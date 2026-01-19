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

    // This test documents the current behavior: effect events do NOT have
    // stable referential identity across builds. This differs from React's
    // useEffectEvent which returns a stable reference. As a consequence, effect
    // events should never be included in useEffect's keys.
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
