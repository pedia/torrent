import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class FlipNumber extends StatelessWidget {
  const FlipNumber({
    super.key,
    required this.number,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.textStyle,
    this.wholeDigits = 1,
    this.fractionDigits = 0,
    this.thousandSeparator,
    this.decimalSeparator = '.',
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.padding = EdgeInsets.zero,
  })  : assert(wholeDigits >= 0, 'wholeDigits must be non-negative'),
        assert(fractionDigits >= 0, 'fractionDigits must be non-negative');

  /// The number value of this counter.
  ///
  /// When a new value is specified, the counter will automatically animate
  /// from its old value to the new value.
  final num number;

  /// The duration over which to animate the value of this counter.
  final Duration duration;

  /// The curve to apply when animating the value of this counter.
  final Curve curve;

  /// If non-null, the style to use for the counter text.
  ///
  /// Similar to the TextStyle property of Text widget, the style will
  /// be merged with the closest enclosing [DefaultTextStyle].
  final TextStyle? textStyle;

  /// How many digits to display, before the decimal point.
  ///
  /// For example, `wholeDigits: 4` means it will pad `48` into `0048`.
  /// Default value is `1`, setting it to `0` would turn `0.7` into `.7`.
  /// If the actual [number] has more digits, this property will be ignored.
  final int wholeDigits;

  /// How many digits to display, after the decimal point.
  ///
  /// The actual [number] will be rounded to the nearest digit.
  final int fractionDigits;

  /// Insert a symbol between every 3 digits, for example: 1,000,000.
  ///
  /// Typical symbol is either a comma or a period, based on locale. Default
  /// value is null, which disables this feature.
  final String? thousandSeparator;

  /// Insert a symbol between the integer part and the fractional part.
  ///
  /// Default value is a period. Can be changed to a comma for certain locale.
  final String decimalSeparator;

  /// How the digits should be placed. Can be used to control text alignment.
  ///
  /// Default value is `MainAxisAlignment.center`, which aligns the digits to
  /// the center, similar to `TextAlign.center`. To mimic `TextAlign.start`,
  /// set the value to `MainAxisAlignment.start`.
  final MainAxisAlignment mainAxisAlignment;

  /// The padding around each of the digits, defaults to 0.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(textStyle);
    // Layout number '8' (probably the widest digit) to see its size
    final layout = TextPainter(
      text: TextSpan(text: '8', style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    )..layout();

    // Find the text color (or red as warning). This is so we can avoid using
    // `Opacity` and `AnimatedOpacity` widget, for better performance.
    final color = style.color ?? const Color(0xffff0000);

    // Convert the decimal value to int. For example, if we want 2 decimal
    // places, we will convert 5.21 into 521.
    final value = (number * math.pow(10, fractionDigits)).round();

    // Split the integer value into separate digits.
    // For example, to draw 521, we split it into [5, 52, 521].
    var digits = value == 0 ? [0] : <int>[];
    var v = value.abs();
    while (v > 0) {
      digits.add(v);
      v = v ~/ 10;
    }
    while (digits.length < wholeDigits + fractionDigits) {
      digits.add(0); // padding leading zeroes
    }
    digits = digits.reversed.toList(growable: false);

    // Generate the widgets needed for digits before the decimal point.
    final integerWidgets = <Widget>[];
    for (var i = 0; i < digits.length - fractionDigits; i++) {
      final digit = SingleDigitFlipCounter(
        key: ValueKey(digits.length - i),
        value: digits[i].toDouble(),
        duration: duration,
        curve: curve,
        size: layout.size,
        color: color,
        padding: padding,
      );
      integerWidgets.add(digit);
    }
    // Insert 'thousand separator' widgets if needed.
    if (thousandSeparator != null) {
      var counter = 0;
      for (var i = integerWidgets.length; i > 0; i--) {
        if (counter > 0 && counter % 3 == 0) {
          integerWidgets.insert(i, Text(thousandSeparator!));
        }
        counter++;
      }
    }

    return DefaultTextStyle.merge(
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          ClipRect(
            child: TweenAnimationBuilder(
              // Animate the negative sign (-) appear and disappearing
              duration: duration,
              tween: Tween(end: value < 0 ? 1.0 : 0.0),
              builder: (_, double v, __) => Center(
                widthFactor: v,
                child: Opacity(opacity: v, child: const Text('-')),
              ),
            ),
          ),
          // Draw digits before the decimal point
          ...integerWidgets,
          // Draw the decimal point
          if (fractionDigits != 0) Text(decimalSeparator),
          // Draw digits after the decimal point
          for (int i = digits.length - fractionDigits; i < digits.length; i++)
            SingleDigitFlipCounter(
              key: ValueKey('decimal$i'),
              value: digits[i].toDouble(),
              duration: duration,
              curve: curve,
              size: layout.size,
              color: color,
              padding: padding,
            ),
        ],
      ),
    );
  }
}

class SingleDigitFlipCounter extends StatelessWidget {
  const SingleDigitFlipCounter({
    Key? key,
    required this.value,
    required this.duration,
    required this.curve,
    required this.size,
    required this.color,
    required this.padding,
  }) : super(key: key);

  final double value;
  final Duration duration;
  final Curve curve;
  final Size size;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(end: value),
      duration: duration,
      curve: curve,
      builder: (_, double value, __) {
        final whole = value ~/ 1;
        final decimal = value - whole;
        final w = size.width + padding.horizontal;
        final h = size.height + padding.vertical;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: <Widget>[
              _buildSingleDigit(whole % 10, h * decimal, 1 - decimal),
              _buildSingleDigit((whole + 1) % 10, h * decimal - h, decimal),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleDigit(int digit, double offset, double opacity) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: offset + padding.bottom,
      child: color.opacity == 1
          ?
          // Try to avoid using the `Opacity` widget when possible, for performance.
          //
          // If the text style does not involve transparency, we can modify
          // the text color directly.
          Text(
              '$digit',
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withOpacity(opacity.clamp(0, 1))),
            )
          :
          // Otherwise, we have to use the `Opacity` widget (less performant).
          Opacity(
              opacity: opacity.clamp(0, 1),
              child: Text('$digit', textAlign: TextAlign.center),
            ),
    );
  }
}
