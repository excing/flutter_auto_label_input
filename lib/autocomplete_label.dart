library flutter_autocomplete_label;

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_offset/flutter_widget_offset.dart';

/// The type of [AutocompleteLabel] callback,
/// which returns a widget that displays the specified label.
///
/// The label can be obtained in the [AutocompleteLabelController.values] attribute.
///
/// See also:
///
///   * [AutocompleteLabel.valueViewBuilder], which is of this type.
typedef ValueViewBuilder<T> = Widget Function(
  BuildContext context,
  ValueOnDeleted onDeleted,
  int index,
  T value,
);

/// The type of [AutocompleteLabel] callback.
/// It returns a widget that wraps all labels and input boxes [textField],
/// and can call [valueViewBuilder] to create a label widget.
///
/// See also:
///
///   * [AutocompleteLabel.valueBoxBuilder], which is of this type.
typedef ValueBoxBuilder<T> = Widget Function(
  BuildContext context,
  ValueOnDeleted onDeleted,
  ValueViewBuilder valueViewBuilder,
  Widget textField,
  Iterable<T> values,
);

/// The type of the callback used by the [AutocompleteLabel] widget to indicate
/// that the user has deleted an entered label.
///
/// See also:
///
///   * [AutocompleteLabel.onDeleted], which is of this type.
typedef ValueOnDeleted = void Function(int index);

/// The type of [AutocompleteLabel] callback,
/// which returns a widget that displays the specified option.
///
/// See also:
///
///   * [AutocompleteLabel.optionViewBuilder], which is of this type.
typedef OptionViewBuilder<T> = Widget Function(
  BuildContext context,
  OnSelected onSelected,
  int index,
  T option,
  bool isHighlight,
);

/// The type of [AutocompleteLabel] callback,
/// which returns a widget that wraps all options.
///
/// See also:
///
///   * [AutocompleteLabel.optionBoxBuilder], which is of this type.
typedef OptionBoxBuilder<T> = Widget Function(
  BuildContext context,
  OnSelected onSelected,
  OptionViewBuilder optionViewBuilder,
  Iterable<T> options,
  int highlightIndex,
  AxisDirection boxDirection,
);

/// The type of the callback used by the [AutocompleteLabel] widget to indicate
/// that the user has selected an option.
///
/// See also:
///
///   * [AutocompleteLabel.onSelected], which is of this type.
typedef OnSelected<T extends Object> = void Function(int index);

/// The type of the [AutocompleteLabel] callback
/// which computes the list of optional completions
/// for the widget's field based on the text the user has entered so far.
///
/// See also:
///
///   * [AutocompleteLabel.optionsBuilder], which is of this type.
typedef OptionsBuilder<T> = Iterable<T> Function(String text);

/// The type of the Autocomplete callback which returns the widget that
/// contains the input [TextField] or [TextFormField].
///
/// See also:
///
///   * [AutocompleteLabel.fieldViewBuilder], which is of this type.
typedef FieldViewBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
  FocusNode focusNode,
  VoidCallback onFieldSubmitted,
);

/// The type of the [AutocompleteLabel] callback
/// which computes the value of label
/// for the widget's field based on the text the user has entered so far.
///
/// See also:
///
///   * [AutocompleteLabel.valueBuilder], which is of this type.
typedef ValueBuilder<T> = T Function(String text);

/// The type of the [AutocompleteLabel] callback that converts an option value to
/// a string which can be displayed in the widget's options menu.
///
/// See also:
///
///   * [AutocompleteLabel.displayStringForOption], which is of this type.
typedef OptionToString<T> = String Function(T option);

/// The type of the callback used by the [AutocompleteLabel] widget to indicate
/// that the values has changed.
///
/// See also:
///
///   * [AutocompleteLabel.onChanged], which is of this type.
typedef OnChanged<T> = void Function(Iterable<T> values);

/// A controller for an editable autocomplete label field.
/// Whenever the user uses the associated [AutocompleteLabelController] to
/// modify the label field,
/// the label field will update [values]
/// and the controller will notify its listener.
class AutocompleteLabelController<T> extends ChangeNotifier {
  AutocompleteLabelController({
    List<T>? source,
    List<T>? values,
  })  : this._source = source ?? [],
        this.values = values ?? [];

  static const _none = -1;

  /// The current values stored in this notifier.
  ///
  /// When the values is replaced with something that
  /// is not equal to the old values as evaluated by
  /// the equality operator ==, this class notifies its listeners.
  ///
  /// Call the public methods of [values] directly,
  /// such as [List.add], [List.remove], etc.,
  /// then this class will not notify its listeners.
  final List<T> values;

  set values(List<T> newValues) {
    if (values == newValues) return;
    values = newValues;
    notifyListeners();
  }

  final List<T> _source;
  final List<T> _options = [];

  int _selectOptionIndex = _none;

  bool get _isSelectOption => _none != _selectOptionIndex;

  T? get _selectOption =>
      _none == _selectOptionIndex ? null : _options[_selectOptionIndex];

  /// Add a [value] to [values] and this class notifies its listeners
  void add(T value) {
    values.add(value);
    _selectOptionIndex = _none;
    notifyListeners();
  }

  /// Add a [values] to [AutocompleteLabelController.values]
  /// and this class notifies its listeners
  void addAll(List<T> values) {
    this.values.addAll(values);
    _selectOptionIndex = _none;
    notifyListeners();
  }

  /// Add a [values] to [AutocompleteLabelController.values]
  /// and this class notifies its listeners
  void remove(T value) {
    values.remove(value);
    notifyListeners();
  }

  /// Remove a value with a specified [index] in [values]
  /// and this class notifies its listeners
  void removeIndex(int i) {
    remove(values[i]);
  }

  /// Remove the last value in [values]
  /// and this class notifies its listeners
  void removeLast() {
    if (0 == values.length) return;
    values.removeLast();
    notifyListeners();
  }

  void _upOption() {
    _selectOptionIndex--;
    if (_selectOptionIndex < 0) {
      _selectOptionIndex = _options.length - 1;
    }
  }

  void _downOption() {
    _selectOptionIndex++;
    if (_options.length <= _selectOptionIndex) {
      _selectOptionIndex = 0;
    }
  }

  void _cancelSelected() {
    _selectOptionIndex = _none;
  }
}

/// A widget that helps the user to select a label
/// by entering some text and selecting from a list of options.
///
/// The autocomplete label calls the [onChanged] callback whenever the user changes the values in the field.
///
/// To control the values that is displayed in the autocomplete label,
/// use the [autocompleteLabelController].
/// For example, to set the initial values of the autocomplete label,
/// use a controller that already contains some values.
/// The controller can also control the selectable
/// label options source (and to observe changes to the values).
///
/// Reading values:
///
/// A common way to read a values from a [AutocompleteLabel] is to use the [onChanged] callback.
/// This callback is applied to the autocomplete label's current values
/// when the user finishes editing or selected option.
///
/// For most applications the [onChanged] callback will be sufficient for reacting to user input.
///
/// Keep in mind you can also always read the current string
/// from a AutocompleteLabel's [AutocompleteLabelController]
/// using [AutocompleteLabelController.text].
class AutocompleteLabel<T> extends StatefulWidget {
  /// Build a single item widget of the deletable label values widgets
  /// from the value of the specified index
  ///
  /// If not provided, a standard Material-style text button
  /// with a delete icon will be built by default.
  final ValueViewBuilder valueViewBuilder;

  /// Builds the deletable label values widgets(which is value box)
  /// from textField and a list of values objects.
  ///
  /// If not provided, [valueViewBuilder] will be used to
  /// build a standard Material-style Wrap list by default.
  ///
  /// See also:
  ///
  ///   * [fieldViewBuilder], which is the builder that creates the textField.
  ///   * [valueViewBuilder], which is a builder for building a single item.
  final ValueBoxBuilder valueBoxBuilder;

  /// Build a single item widget of the selectable label options widgets
  /// from the option of the specified index.
  ///
  /// If not provided, will build a standard Material-style text by default.
  final OptionViewBuilder optionViewBuilder;

  /// Builds the selectable label options widgets(which is option box) from a list of values objects.
  ///
  /// These options use the [CompositedTransformFollower]
  /// in Overlay to float below or above [valueBoxBuilder],
  /// and their position depends on the [optionBoxDirection] property.
  ///
  /// If not provided, will build a standard Material-style list of results by default.
  ///
  /// See also:
  ///
  ///   * [optionBoxDirection], which is the attribute.
  /// that indicates the direction of the [valueBoxBuilder].
  ///   * [optionViewBuilder], which is a builder for building a single item.
  final OptionBoxBuilder optionBoxBuilder;

  /// Builds the field whose input is used to get the options.
  ///
  /// Pass the provided [TextEditingController] to
  /// the field built here so that [AutocompleteLabel] can listen for changes.
  ///
  /// If not provided, a borderless text field
  /// of material style will be constructed by default,
  /// wrapped in the [DryIntrinsicWidth] widget, the width of 68.
  ///
  /// See also:
  ///
  ///   * [DryIntrinsicWidth], which is useful in situations
  /// where the `child` does not support dry layout.
  final FieldViewBuilder fieldViewBuilder;

  /// Controls the values being edited.
  ///
  /// If null, this widget will create its own AutocompleteLabelController.
  final AutocompleteLabelController autocompleteLabelController;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own TextEditingController.
  final TextEditingController textEditingController;

  /// A function that returns the current selectable label option objects given the current string.
  final OptionsBuilder? optionsBuilder;

  /// A function that returns the label object given the current string.
  final ValueBuilder valueBuilder;

  /// Returns the string to display in the field when the label option is selected.
  /// This is useful when using a custom T type and
  /// the string to display is different than the string to search by.
  ///
  /// If not provided, will use option.toString().
  final OptionToString displayStringForOption;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a [StatefulWidget] parent.
  /// See [TextField.focusNode] for more information.
  ///
  /// If null, this widget will create its own [FocusNode].
  ///
  /// ### Keyboard
  ///
  /// On Android, the user can hide the keyboard -
  /// without changing the focus - with the system back button.
  /// They can restore the keyboard's visibility by tapping on a text field.
  /// But we can set [keepAutofocus] to change this.
  ///
  /// See also:
  ///
  ///   * [keepAutofocus], which is to set whether to still have the focus when the keyboard is hidden.
  final FocusNode focusNode;

  /// Whether to keep the focus automatically, this `autofocus` is not [TextField.autofocus].
  ///
  /// [keepAutofocus] is used in two places, one is when the soft keyboard disappears,
  /// and the other is when you click outside the option box.
  ///
  /// If it is false, close the option box when you click outside the option box.
  /// When the keyboard is hidden, the option box will be closed,
  /// and the textField of [AutocompleteLabel] will also lose focus.
  ///
  /// If it is true, when the soft keyboard is hidden,
  /// on Android, the soft keyboard can only be popped up by clicking the textField.
  /// For details, refer to [TextField.focusNode].
  ///
  /// See also:
  ///
  ///   * [TextField.focusNode], defines the keyboard focus for the textField
  final bool keepAutofocus;

  /// Called when the user initiates a change to the AutocompleteLabel's values:
  /// when they have inserted or deleted value.
  final OnChanged? onChanged;

  /// The minimum height of the selectable label options widgets.
  ///
  /// The [minOptionBoxHeight] is only available when [optionBoxDirection] is null.
  ///
  /// If not provided, the default value is 100.
  ///
  /// See also:
  ///
  ///   * [optionBoxDirection], control the vertical direction of the option box
  final double minOptionBoxHeight;

  /// The vertical direction attribute of the selectable label options widgets.
  ///
  /// If it's [VerticalDirection.up],
  /// the option box is fixed above the textField,
  /// and if it's [VerticalDirection.down], it's below it.
  ///
  /// If it's `null`, the vertical position of the appropriate option box
  /// will be calculated automatically.
  /// The calculation method is that when the offset of the textField from
  /// the bottom of the root layout is greater than [minOptionBoxHeight]
  /// or greater than the offset from the top,
  /// the option box is located below the textField,
  /// otherwise it is located above it.
  ///
  /// See also:
  ///
  ///   * [minOptionBoxHeight], which is the minimum height of the option box.
  final VerticalDirection? optionBoxDirection;

  /// Creates an instance of [AutocompleteLabel].
  AutocompleteLabel({
    Key? key,
    this.valueViewBuilder = defaultValueViewBuilder,
    this.valueBoxBuilder = defaultValueBoxBuilder,
    this.optionViewBuilder = defaultOptionViewBuilder,
    this.optionBoxBuilder = defaultOptionBoxBuild,
    this.fieldViewBuilder = defaultFieldViewBuilder,
    AutocompleteLabelController? autocompleteLabelController,
    TextEditingController? textEditingController,
    this.optionsBuilder,
    this.valueBuilder = defaultValueBuilder,
    FocusNode? focusNode,
    this.onChanged,
    this.minOptionBoxHeight = 100,
    this.keepAutofocus = true,
    this.displayStringForOption = defaultStringForOption,
    this.optionBoxDirection,
  })  : this.focusNode = focusNode ?? FocusNode(),
        this.autocompleteLabelController =
            autocompleteLabelController ?? AutocompleteLabelController(),
        this.textEditingController =
            textEditingController ?? TextEditingController(),
        super(key: key);

  static const _defaultFontSize = 16.0;

  /// The default way to build the single item of the value box in [valueViewBuilder].
  static Widget defaultValueViewBuilder(BuildContext context,
      ValueOnDeleted onDeleted, int index, dynamic value) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onDeleted(index),
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(value.toString(),
                style: TextStyle(fontSize: _defaultFontSize)),
            Icon(
              Icons.close,
              size: _defaultFontSize,
            ),
          ],
        ),
      ),
    );
  }

  /// The default way to build the deletable label values widgets in [valueBoxBuilder].
  static Widget defaultValueBoxBuilder(
    BuildContext context,
    ValueOnDeleted onDeleted,
    ValueViewBuilder valueViewBuilder,
    Widget textField,
    Iterable<dynamic> values,
  ) {
    List<Widget> valueItems = [];
    for (var i = 0; i < values.length; i++) {
      var value = values.elementAt(i);
      valueItems.add(valueViewBuilder(context, onDeleted, i, value));
    }
    valueItems.add(textField);

    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 3),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(
          color: Colors.grey,
          width: 1.0,
          style: BorderStyle.solid,
        )),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 3,
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.end,
        textDirection: TextDirection.ltr,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: valueItems,
      ),
    );
  }

  /// The default way to build the single item of the option box in [optionViewBuilder].
  static Widget defaultOptionViewBuilder(BuildContext context,
      OnSelected onSelected, int index, dynamic option, bool isHighlight) {
    return InkWell(
      onTap: () => onSelected(index),
      child: Container(
        padding: EdgeInsets.all(10.0),
        color: isHighlight ? Colors.grey[350] : null,
        child: Text(option.toString()),
      ),
    );
  }

  /// The default way to build the selectable label options widgets in [optionBoxBuilder].
  static Widget defaultOptionBoxBuild(
    BuildContext context,
    OnSelected onSelected,
    OptionViewBuilder optionViewBuilder,
    Iterable<dynamic> options,
    int highlightIndex,
    AxisDirection boxDirection,
  ) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        return optionViewBuilder(context, onSelected, index,
            options.elementAt(index), highlightIndex == index);
      },
    );
  }

  /// The default way to build the text field widget in [fieldViewBuilder].
  static Widget defaultFieldViewBuilder(
    BuildContext context,
    TextEditingController textEditingController,
    FocusNode focusNode,
    VoidCallback onFieldSubmitted,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 68),
      child: DryIntrinsicWidth(
        child: Padding(
          padding: EdgeInsets.all(5),
          child: TextField(
            focusNode: focusNode,
            style: TextStyle(fontSize: AutocompleteLabel._defaultFontSize),
            strutStyle: StrutStyle(height: 1.0),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              border: InputBorder.none,
              hintText: "Write label",
            ),
            autofocus: true,
            controller: textEditingController,
            textInputAction: TextInputAction.next,
            onEditingComplete: onFieldSubmitted,
          ),
        ),
      ),
    );
  }

  /// The default way to convert an string to a label value in [valueBuilder].
  ///
  /// Simply uses the `trim().toString()` method on the value.
  static dynamic defaultValueBuilder(String value) {
    return value.trim();
  }

  /// The default way to convert an option to a string in [displayStringForOption].
  ///
  /// Simply uses the `toString` method on the option.
  static String defaultStringForOption(dynamic option) {
    return option.toString().trim();
  }

  @override
  State<StatefulWidget> createState() {
    return _AutocompleteLabelState();
  }
}

class _AutocompleteLabelState<T> extends State<AutocompleteLabel> {
  final LayerLink _layerLink = LayerLink();
  late OverlayEntry? _overlayEntry;

  double _overlayEntryWidth = 100.0;
  double _overlayEntryHeight = 100.0;
  double _overlayEntryY = double.minPositive;
  AxisDirection _overlayEntryDir = AxisDirection.down;

  late OffsetDetectorController _offsetDetectorController;

  bool isOpened = false;
  bool _isSelectOption = false;
  GlobalKey _textFieldKey = GlobalKey();

  String _oldValue = "";

  void _openOptionBox() {
    if (this.isOpened) return;
    assert(this._overlayEntry != null);
    Overlay.of(context).insert(this._overlayEntry!);
    this.isOpened = true;
  }

  void _closeOptionBox() {
    if (!this.isOpened) return;
    assert(this._overlayEntry != null);
    this._overlayEntry!.remove();
    this.isOpened = false;
  }

  void _updateOptionBox() {
    if (!this.isOpened) return;
    assert(this._overlayEntry != null);
    this._overlayEntry!.markNeedsBuild();
  }

  @override
  void initState() {
    super.initState();

    widget.autocompleteLabelController.addListener(_handleValuesChanged);
    widget.textEditingController.addListener(_handleTextChanged);
    _offsetDetectorController = OffsetDetectorController();
    SchedulerBinding.instance.addPostFrameCallback((duration) {
      if (mounted) {
        _overlayEntry = _createOverlayEntry();
      }
    });

    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AutocompleteLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    if (widget.autocompleteLabelController !=
        oldWidget.autocompleteLabelController) {
      oldWidget.autocompleteLabelController
          .removeListener(_handleValuesChanged);
      widget.autocompleteLabelController.addListener(_handleValuesChanged);
    }
    if (widget.textEditingController != oldWidget.textEditingController) {
      oldWidget.textEditingController.removeListener(_handleTextChanged);
      widget.textEditingController.addListener(_handleTextChanged);
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _updateOptionBox();
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.autocompleteLabelController.removeListener(_handleValuesChanged);
    widget.textEditingController.removeListener(_handleTextChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    _detachKeyboardListenerIfAttached();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final optionsBox = Material(
          elevation: 2.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _overlayEntryHeight,
            ),
            child: widget.optionBoxBuilder(
              context,
              _onSelected,
              widget.optionViewBuilder,
              widget.autocompleteLabelController._options,
              widget.autocompleteLabelController._selectOptionIndex,
              _overlayEntryDir,
            ),
          ),
        );
        final optionsBoxPositioned = Positioned(
            width: _overlayEntryWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              followerAnchor: _overlayEntryDir == AxisDirection.down
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              targetAnchor: Alignment.bottomLeft,
              offset: Offset(0.0, _overlayEntryY),
              child: optionsBox,
            ));
        return !widget.keepAutofocus
            ? Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _closeOptionBox(),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  optionsBoxPositioned,
                ],
              )
            : optionsBoxPositioned;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = widget.fieldViewBuilder(
        context, widget.textEditingController, widget.focusNode, () {
      _onEditingComplete();
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          // FocusScope.of(context).requestFocus(FocusNode());
          widget.focusNode.requestFocus();
        },
        child: OffsetDetector(
          controller: _offsetDetectorController,
          onChanged: _onBoxOffsetChanged,
          onKeyboard: _onKeyboardState,
          child: widget.valueBoxBuilder(
            context,
            _onDeleted,
            widget.valueViewBuilder,
            Container(
              key: _textFieldKey,
              child: textField,
            ),
            widget.autocompleteLabelController.values,
          ),
        ),
      ),
    );
  }

  void _onDeleted(int index) {
    widget.autocompleteLabelController.removeIndex(index);
  }

  void _onSelected(int index) {
    widget.autocompleteLabelController
        .add(widget.autocompleteLabelController._options[index]);
  }

  void _onBoxOffsetChanged(
      Size size, EdgeInsets offset, EdgeInsets rootPadding) {
    RenderBox? box =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || box.hasSize == false) {
      return;
    }

    double textFieldHeight = box.size.height;
    double cursorOffsetTop = offset.top + size.height - textFieldHeight;

    // print("cursorOffsetTop: $cursorOffsetTop, _courseHeight: $_courseHeight");
    if (widget.optionBoxDirection == VerticalDirection.down ||
        (widget.optionBoxDirection == null &&
            (widget.minOptionBoxHeight < offset.bottom ||
                cursorOffsetTop < offset.bottom))) {
      _overlayEntryHeight = offset.bottom - 5.0;
      _overlayEntryY = 1.0;
      _overlayEntryDir = AxisDirection.down;
    } else {
      _overlayEntryHeight = cursorOffsetTop - 5.0;
      _overlayEntryY = -textFieldHeight - 1.0;
      _overlayEntryDir = AxisDirection.up;
    }

    _overlayEntryWidth = size.width;

    _updateOptionBox();
  }

  void _handleOptionsBuilder(String text) {
    for (int i = 0;
        i < widget.autocompleteLabelController._source.length;
        i++) {
      var item = widget.autocompleteLabelController._source[i];
      if (widget
              .displayStringForOption(item)
              .toLowerCase()
              .contains(text.trim().toLowerCase()) &&
          !widget.autocompleteLabelController.values.contains(item)) {
        widget.autocompleteLabelController._options.add(item);
      }
    }
  }

  void _handleTextChanged() {
    if (_isSelectOption) {
      _isSelectOption = false;
      return;
    }

    String value = widget.textEditingController.text;
    String oldValue = _oldValue;

    if (value == oldValue) {
      return;
    }

    widget.autocompleteLabelController._options.clear();
    widget.autocompleteLabelController._cancelSelected();

    _oldValue = value;

    if (value == "") {
      _closeOptionBox();
      return;
    }

    final lastChar = value.substring(value.length - 1);
    if (lastChar == '\n' || lastChar == "," || lastChar == "，") {
      _onAddLabel(widget.valueBuilder(value.substring(0, value.length - 1)));
      return;
    }

    if (widget.optionsBuilder != null) {
      widget.autocompleteLabelController._options
          .addAll(widget.optionsBuilder!(value));
    } else {
      _handleOptionsBuilder(value);
    }

    if (0 < widget.autocompleteLabelController._options.length) {
      _openOptionBox();
      _offsetDetectorController.notifyStateChanged();
    }
  }

  void _onEditingComplete() {
    if (widget.autocompleteLabelController._isSelectOption) {
      _onAddLabel(widget.autocompleteLabelController._selectOption);
    } else if (widget.textEditingController.text.isNotEmpty) {
      _onAddLabel(widget.valueBuilder(widget.textEditingController.text));
    }
    FocusScope.of(context).requestFocus(widget.focusNode);
  }

  void _onAddLabel(T value) {
    _closeOptionBox();
    widget.autocompleteLabelController.add(value);
    widget.textEditingController.text = "";
  }

  void _selectOption() {
    _isSelectOption = true;
    final optionText = widget.displayStringForOption(
        widget.autocompleteLabelController._selectOption);
    widget.textEditingController.value = TextEditingValue(
      text: optionText,
      selection: TextSelection.collapsed(offset: optionText.length),
    );

    _updateOptionBox();
  }

  void _onKeyEvent(RawKeyEvent value) {
    _onKeyDownEvent(value);
    _onKeyUpEvent(value);
  }

  void _onKeyDownEvent(RawKeyEvent value) {
    if (!(value is RawKeyDownEvent)) return;

    if (widget.textEditingController.text == "" &&
        value.logicalKey == LogicalKeyboardKey.backspace) {
      widget.autocompleteLabelController.removeLast();
      _updateOptionBox();
    } else if (value.logicalKey == LogicalKeyboardKey.escape) {
      if (!isOpened) return;
      if (widget.autocompleteLabelController._selectOptionIndex ==
          AutocompleteLabelController._none) {
        _closeOptionBox();
      } else {
        widget.autocompleteLabelController._cancelSelected();
        _updateOptionBox();
      }
    } else {
      _updateOptionBox();
    }
  }

  void _onKeyUpEvent(RawKeyEvent value) {
    if (!(value is RawKeyUpEvent)) return;

    if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (!isOpened) return;
      widget.autocompleteLabelController._upOption();
      _selectOption();
    } else if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!isOpened) return;
      widget.autocompleteLabelController._downOption();
      _selectOption();
    }
  }

  void _handleFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _attachKeyboardListenerIfDetached();
    } else {
      _detachKeyboardListenerIfAttached();
    }
  }

  bool _listening = false;

  void _attachKeyboardListenerIfDetached() {
    if (_listening) return;
    // Keyboard events are not available on iOS yet ...
    // https://github.com/flutter/flutter/issues/62774
    if (!kIsWeb && Platform.isIOS) {
      widget.textEditingController.addListener(_simulateRawKeyEvent);
    } else {
      RawKeyboard.instance.addListener(_handleRawKeyEvent);
    }
    _listening = true;
  }

  void _detachKeyboardListenerIfAttached() {
    if (!_listening) return;
    // Keyboard events are not available on iOS yet ...
    // https://github.com/flutter/flutter/issues/62774
    if (!kIsWeb && Platform.isIOS) {
      widget.textEditingController.removeListener(_simulateRawKeyEvent);
    } else {
      RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    }
    _listening = false;
  }

  void _simulateRawKeyEvent() {
    String value = widget.textEditingController.text;
    final event = RawKeyDownEvent(data: RawKeyEventDataAndroid(), character: value);
    _handleRawKeyEvent(event);
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    _onKeyEvent.call(event);
  }

  void _handleValuesChanged() {
    if (!mounted) return;
    _closeOptionBox();
    setState(() {});
    if (widget.onChanged != null) {
      widget.onChanged!(widget.autocompleteLabelController.values);
    }
    widget.textEditingController.text = "";
    _offsetDetectorController.notifyStateChanged();
  }

  void _onKeyboardState(bool state) {
    if (widget.keepAutofocus) return;

    if (!state) {
      _closeOptionBox();
      widget.focusNode.unfocus();
    } else {
      _openOptionBox();
    }
  }
}

/// Same as `IntrinsicWidth` except that when this widget is instructed
/// to `computeDryLayout()`, it doesn't invoke that on its child, instead
/// it computes the child's intrinsic width.
///
/// This widget is useful in situations where the `child` does not
/// support dry layout, e.g., `TextField` as of 01/02/2021.
///
/// see [dry_layout_stop_gap.dart](https://gist.github.com/matthew-carroll/65411529a5fafa1b527a25b7130187c6)
///
/// See also:
///
///   * [IntrinsicWidth], which is a widget that sizes its child to the child's maximum intrinsic width.
class DryIntrinsicWidth extends SingleChildRenderObjectWidget {
  const DryIntrinsicWidth({Key? key, Widget? child})
      : super(key: key, child: child);

  @override
  _RenderDryIntrinsicWidth createRenderObject(BuildContext context) =>
      _RenderDryIntrinsicWidth();
}

class _RenderDryIntrinsicWidth extends RenderIntrinsicWidth {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child != null) {
      final width = child!.computeMinIntrinsicWidth(constraints.maxHeight);
      final height = child!.computeMinIntrinsicHeight(width);
      return Size(width, height);
    } else {
      return Size.zero;
    }
  }
}
