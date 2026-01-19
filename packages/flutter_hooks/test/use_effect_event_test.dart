import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useEffectEvent', () {
    testWidgets('effect event should always invoke callback with latest state',
        (tester) async {
      late void Function() event;
      late int expectedNumber;
      int? capturedNumber;

      Widget buildWidget() {
        return HookBuilder(
          builder: (context) {
            final current = expectedNumber;
            event = useEffectEvent(() {
              capturedNumber = current;
            });
            return const SizedBox();
          },
        );
      }

      expectedNumber = 42;
      await tester.pumpWidget(buildWidget());
      event();
      expect(capturedNumber, 42);

      expectedNumber = 21;
      await tester.pumpWidget(buildWidget());
      event();
      expect(capturedNumber, 21);
    });

    testWidgets('effect event should pass in provided arguments to callback',
        (tester) async {
      late void Function(String args) event;
      String? capturedArgs;

      Widget buildWidget() {
        return HookBuilder(
          builder: (context) {
            event = useEffectEvent((args) {
              capturedArgs = args;
            });
            return const SizedBox();
          },
        );
      }

      await tester.pumpWidget(buildWidget());
      event('Hello');
      expect(capturedArgs, 'Hello');

      await tester.pumpWidget(buildWidget());
      event('World!');
      expect(capturedArgs, 'World!');
    });

    testWidgets('effect event should return value returned by callback',
        (tester) async {
      late String Function() event;
      late String expectedReturnValue;

      Widget buildWidget() {
        return HookBuilder(
          builder: (context) {
            event = useEffectEvent(() {
              return expectedReturnValue;
            });
            return const SizedBox();
          },
        );
      }

      expectedReturnValue = 'Hello';
      await tester.pumpWidget(buildWidget());
      expect(event(), 'Hello');

      expectedReturnValue = 'World!';
      await tester.pumpWidget(buildWidget());
      expect(event(), 'World!');
    });

    /// Simulates the example use case: effect depends on `url` but reads
    /// `itemCount` via useEffectEvent without adding it to dependencies.
    testWidgets(
        'effect re-runs only when keys change, not when captured values change',
        (tester) async {
      final loggedVisits = <String>[];
      var effectRunCount = 0;

      await tester.pumpWidget(
        Page(
          url: '/home',
          itemCount: 5,
          onVisit: loggedVisits.add,
          onEffect: () => effectRunCount++,
        ),
      );

      expect(effectRunCount, 1);
      expect(loggedVisits, ['/home:5']);

      // Change itemCount only
      await tester.pumpWidget(
        Page(
          url: '/home',
          itemCount: 10,
          onVisit: loggedVisits.add,
          onEffect: () => effectRunCount++,
        ),
      );

      // Should NOT have re-run effect, no new log
      expect(effectRunCount, 1);
      expect(loggedVisits, ['/home:5']);

      // Change url
      await tester.pumpWidget(
        Page(
          url: '/about',
          itemCount: 10,
          onVisit: loggedVisits.add,
          onEffect: () => effectRunCount++,
        ),
      );

      // Should have re-ran effect, new log with latest itemCount
      expect(effectRunCount, 2);
      expect(loggedVisits, ['/home:5', '/about:10']);
    });

    /// This test documents the current behavior: effect events do NOT have
    /// stable referential identity across builds. This differs from React's
    /// useEffectEvent which returns a stable reference. As a consequence,
    /// effect events should never be included in useEffect's keys.
    testWidgets('returns different identity on each build', (tester) async {
      final identities = <Function>[];

      Widget buildWidget() {
        return HookBuilder(
          builder: (context) {
            final event = useEffectEvent(() {});
            identities.add(event);
            return const SizedBox();
          },
        );
      }

      await tester.pumpWidget(buildWidget());
      await tester.pumpWidget(buildWidget());
      await tester.pumpWidget(buildWidget());

      expect(identities.length, 3);
      expect(identities[0], isNot(same(identities[1])));
      expect(identities[1], isNot(same(identities[2])));
      expect(identities[2], isNot(same(identities[0])));
    });

    testWidgets('debugFillProperties', (tester) async {
      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          useEffectEvent(() {});
          return const SizedBox();
        }),
      );

      final element = tester.element(find.byType(HookBuilder));

      expect(
        element
            .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
            .toStringDeep(),
        equalsIgnoringHashCodes(
          'HookBuilder\n'
          ' │ useEffectEvent\n'
          ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
        ),
      );
    });
  });
}

class Page extends HookWidget {
  const Page({
    super.key,
    required this.url,
    required this.itemCount,
    required this.onVisit,
    required this.onEffect,
  });

  final String url;
  final int itemCount;
  final void Function(String) onVisit;
  final void Function() onEffect;

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_types_on_closure_parameters
    final logVisit = useEffectEvent((String visitedUrl) {
      onVisit('$visitedUrl:$itemCount');
    });

    useEffect(() {
      onEffect();
      logVisit(url);
      return null;
    }, [url]);

    return const SizedBox();
  }
}
