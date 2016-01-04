//
//  SkyFloatingLabelTextField.swift
//  Demo
//
//  Created by Daniel Langh on 21/12/15.
//  Copyright © 2015 Skyscanner. All rights reserved.
//

import UIKit

// MARK: - UITextField extension

extension UITextField {
    func fixCaretPosition() {
        // TODO: this is a fix for the caret position
        // http://stackoverflow.com/questions/14220187/uitextfield-has-trailing-whitespace-after-securetextentry-toggle
        
        let beginning = self.beginningOfDocument
        self.selectedTextRange = self.textRangeFromPosition(beginning, toPosition: beginning)
        let end = self.endOfDocument
        self.selectedTextRange = self.textRangeFromPosition(end, toPosition: end)
    }
}

// MARK: - SkyFloatingLabelTextFieldDelegate

/**
The `SkyFloatingLabelTextFieldDelegate` protocol defines the messages sent to a text field delegate as part of the sequence of editing its text. All of the methods of this protocol are optional.
*/
@objc public protocol SkyFloatingLabelTextFieldDelegate: class {
    
    /**
     Tells the delegate that editing began for the specified text field.
     
     - parameter textField: The text field for which an editing session began.
    */
    optional func textFieldDidBeginEditing(textField:SkyFloatingLabelTextField)
    
    /**
     Tells the delegate that editing stopped for the specified text field.
     
     - parameter textField: The text field for which the editing session ended.
     */
    optional func textFieldDidEndEditing(textField:SkyFloatingLabelTextField)
    
    /**
     Asks the delegate if the text field should process the pressing of the return button.
     
     - parameter textField: The text field whose return button was pressed.
     */
    optional func textFieldShouldReturn(textField:SkyFloatingLabelTextField) -> Bool
    
    /**
     Asks the delegate if the text field should process the pressing of the clear button.
     
     - parameter textField: The text field whose clear button was pressed.
     */
    optional func textFieldShouldClear(textField:SkyFloatingLabelTextField) -> Bool
    
    /**
     Asks the delegate if editing should begin in the specified text field.
     
     - parameter textField: The text field for which editing is about to begin.
     
     - returns: `true` if an editing session should be initiated; otherwise, `false` to disallow editing.
     */
    optional func textFieldShouldBeginEditing(textField:SkyFloatingLabelTextField) -> Bool
    
    /**
     Asks the delegate if editing should stop in the specified text field.
     
     - parameter textField: The text field for which editing is about to end.
     
     - returns: `true` if editing should stop; otherwise, `false` if the editing session should continue
     */
    optional func textFieldShouldEndEditing(textField:SkyFloatingLabelTextField) -> Bool
    
    
    /**
     Asks the delegate if editing should stop in the specified text field.
     
     - parameter textField: The text field containing the text.
     - parameter range: The range of characters to be replaced.
     - parameter string: The replacement string.
     
     - returns: `true` if the specified text range should be replaced; otherwise, `false` to keep the old text.
     */
    optional func textField(textField: SkyFloatingLabelTextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
}

// MARK: - SkyFloatingLabelTextField

/**
    A beautiful and flexible textfield implementation with support for title label, error message and placeholder.
*/
@IBDesignable
public class SkyFloatingLabelTextField: UIControl, UITextFieldDelegate {

    // MARK: Animation timing
    
    /// The value of the title appearing duration.
    public var titleFadeInDuration:Double = 0.2
    /// The value of the title disappearing duration.
    public var titleFadeOutDuration:Double = 0.3
    
    // MARK: Colors
    
    /// The text color of the editable text.
    @IBInspectable public var textColor:UIColor = UIColor.blackColor() {
        didSet {
            self.updateTextColor()
        }
    }

    /// The text color of the placeholder label.
    @IBInspectable public var placeholderColor:UIColor = UIColor.lightGrayColor() {
        didSet {
            self.placeholderLabel.textColor = placeholderColor
        }
    }
    
    /// The color used for the title label and the line when the error message is not `nil`
    @IBInspectable public var errorColor:UIColor = UIColor.redColor() {
        didSet {
            self.updateColors()
        }
    }
    
    /// The text color of the title label when not editing.
    @IBInspectable public var titleColor:UIColor = UIColor.grayColor() {
        didSet {
            self.updateTitleColor()
        }
    }
    
    /// The text color of the title label when editing.
    @IBInspectable public var selectedTitleColor:UIColor = UIColor.grayColor() {
        didSet {
            self.updateTitleColor()
        }
    }
    
    /// The color of the line when not editing.
    @IBInspectable public var lineColor:UIColor = UIColor.lightGrayColor() {
        didSet {
            self.updateLineView()
        }
    }
    
    /// The color of the line when editing.
    @IBInspectable public var selectedLineColor:UIColor = UIColor.blackColor() {
        didSet {
            self.updateLineView()
        }
    }
    
    // MARK: Line height
    
    @IBInspectable public var lineHeight:Double = 0.5 {
        didSet {
            self.updateLineView()
        }
    }
    
    @IBInspectable public var selectedLineHeight:Double = 1.0 {
        didSet {
            self.updateLineView()
        }
    }
    
    // MARK: Delegate

    /// The `SkyFloatingLabelTextField` delegate.
    @IBOutlet public weak var delegate:SkyFloatingLabelTextFieldDelegate?

    // MARK: View components
    
    /// The internal `UITextField` for text input.
    public var textField:UITextField!
    
    /// The internal `UILabel` that displays the placeholder text when no text input is present.
    public var placeholderLabel:UILabel!
    
    /// The internal `UIView` to display the line below the text input.
    public var lineView:UIView!
    
    /// The internal `UILabel` that displays the selected, deselected title or the error message based on the current state.
    public var titleLabel:UILabel!
    
    // MARK: Properties
    
    /**
        The formatter to use before displaying content in the title label. This can be the `selectedTitle`, `deselectedTitle` or the `errorMessage`.
        The default implementation converts the text to uppercase.
    */
    public var titleFormatter:(String -> String) = { (text:String) -> String in
        return text.uppercaseString
    }
    
    /**
        Identifies whether the text object should hide the text being entered.
    */
    public var secureTextEntry:Bool = false {
        didSet {
            self.textField.secureTextEntry = secureTextEntry
            self.textField.fixCaretPosition()
        }
    }
    
    /// A String value for the error message to display.
    public var errorMessage:String? {
        didSet {
            self.updateControl(true)
        }
    }
    
    /// A Boolean value that determines whether the receiver discards `errorMessage` when the text input is changed.
    public var discardsErrorMessageOnTextChange:Bool = true
    
    /// A Boolean value that determines whether the receiver is enabled.
    override public var enabled:Bool {
        set {
            super.enabled = newValue
            self.textField.enabled = newValue
        }
        get {
            return super.enabled
        }
    }
    
    /// A Boolean value that determines whether the receiver is highlighted.
    override public var highlighted:Bool {
        set {
            super.highlighted = highlighted
//            self.setHighlighted(newValue, animated:false)
        }
        get {
            return super.highlighted
        }
    }
    
    // TODO: clean up api here
    /*
    private func setHighlighted(highlighted:Bool, animated:Bool = false) {
        if(super.highlighted != highlighted) {
            super.highlighted = highlighted
            
            if(highlighted) {
                self.updatePlaceholderLabelVisibility()
                self.updateTitleLabel()
            } else {
                //self.performSelector(Selector("fadeoutHighlighted"), withObject: self, afterDelay: notHighlightedFadeOutDelay)
            }
        }
    }*/
    
    /// A Boolean value that determines if the receiver is currently editing.
    public var editing:Bool {
        get {
            return self.isFirstResponder() || self.tooltipVisible
        }
    }
    
    /// A Boolean value that determines whether the receiver has an error message.
    public var hasErrorMessage:Bool {
        get {
            return self.errorMessage != nil
        }
    }
    
    /// A Boolean value that determines whether the receiver has text input.
    public var hasText:Bool {
        get {
            if let text = self.text {
                return text.characters.count > 0
            }
            return false
        }
    }
    
    private var _titleVisible:Bool = false
    public private(set) var titleVisible:Bool {
        set {
            self.setTitleVisibile(newValue, animated: false)
        }
        get {
            return _titleVisible
        }
    }
    private func setTitleVisibile(titleVisible:Bool, animated:Bool = false) {
        if titleVisible != _titleVisible {
            _titleVisible = titleVisible
            self.updateTitleVisibility(animated)
        }
    }
    
    /// A String value that is displayed in the input field.
    private var _text:String?
    @IBInspectable public var text:String? {
        set {
            self.setText(newValue, animated:false)
        }
        get {
            return _text
        }
    }
    
    public func setText(text:String?, animated:Bool = false) {
        _text = text
        self.textField.text = text
        self.resetErrorMessageIfPresent()
        self.updateControl(animated)
    }
    
    /**
        The String to display when the input field is empty.
        The placeholder can also appear in the title label when both `selectedTitle` and `deselectedTitle` are `nil`.
     */
    @IBInspectable public var placeholder:String? {
        didSet {
            self.placeholderLabel.text = placeholder
            self.updateTitleLabel()
        }
    }
    
    /// The String to display when the textfield is editing and the input is not empty.
    @IBInspectable public var selectedTitle:String? {
        didSet {
            self.updateControl()
        }
    }

    /// The String to display when the textfield is not editing and the input is not empty.
    @IBInspectable public var deselectedTitle:String? {
        didSet {
            self.updateControl()
        }
    }
    
    // TODO: get a better name for this, permanentlySelected?
    public var tooltipVisible:Bool = false {
        didSet {
            self.updateControl(true)
        }
    }
    
    // MARK: - Initializers
    
    public init(frame:CGRect, textField:UITextField?, lineView:UIView?) {
        super.init(frame: frame)
        
        self.lineView = lineView
        self.textField = textField
        self.createLineView()
        self.createTitleLabel()
        self.createPlaceholderLabel()
        self.createTextField()
        self.updateColors()
    }
    
    override convenience init(frame: CGRect) {
        self.init(frame:frame, textField:nil, lineView:nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.createLineView()
        self.createTitleLabel()
        self.createPlaceholderLabel()
        self.createTextField()
        self.updateColors()
    }
    
    // MARK: create components
    
    private func createTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        titleLabel.font = UIFont.systemFontOfSize(13)
        titleLabel.alpha = 0.0
        titleLabel.textColor = self.titleColor
        self.addSubview(titleLabel)
        self.titleLabel = titleLabel
    }
    
    private func createPlaceholderLabel() {
        let placeholderLabel = UILabel()
        placeholderLabel.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        placeholderLabel.font = UIFont.systemFontOfSize(18.0)
        placeholderLabel.textColor = self.placeholderColor
        placeholderLabel.alpha = 1.0
        self.addSubview(placeholderLabel)
        self.placeholderLabel = placeholderLabel
    }
    
    private func createTextField() {
        
        if self.textField == nil {
            let textField = UITextField()
            textField.font = UIFont.systemFontOfSize(18.0)
            self.textField = textField
        }
        textField.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        textField.delegate = self
        textField.addTarget(self, action: Selector("editingDidEndOnExit:"), forControlEvents: .EditingDidEndOnExit)
        textField.addTarget(self, action: Selector("textFieldChanged:"), forControlEvents: .EditingChanged)
        self.addSubview(textField)
    }
    
    private func createLineView() {
        
        if self.lineView == nil {
            let lineView = UIView()
            lineView.userInteractionEnabled = false
            self.lineView = lineView
        }
        lineView.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        self.addSubview(lineView)
    }
    
    // MARK: input
    
    private func installDummyInputView() {
        self.textField.inputView = UIView(frame: CGRectZero)
    }
    
    // MARK: Responder handling
    
    override public func becomeFirstResponder() -> Bool {
        self.textField.userInteractionEnabled = true
        let success = self.textField.becomeFirstResponder()
        if !success {
            self.textField.userInteractionEnabled = false
        }
        self.updateControl(true)
        return success
    }
    
    override public func resignFirstResponder() -> Bool {
        let success = self.textField.resignFirstResponder()
        if success {
            self.textField.userInteractionEnabled = false
        }
        self.updateControl(true)
        return success
    }
    
    override public func isFirstResponder() -> Bool {
        return self.textField.isFirstResponder() || self.textField.editing
    }
    
    // MARK: - View updates
    
    private func updateControl(animated:Bool = false) {
        self.updateColors()
        self.updateLineView()
        self.updateTitleLabel(animated)
        self.updatePlaceholderLabelVisibility()
    }
    
    private func updatePlaceholderLabelVisibility() {
        self.placeholderLabel.hidden = self.hasText
    }
    
    private func updateLineView() {
        if let lineView = self.lineView {
            lineView.frame = self.lineViewRectForBounds(self.bounds, editing: self.editing)
            lineView.backgroundColor = self.editing ? self.selectedLineColor : self.lineColor
        }
    }
    
    // MARK: - Color updates
    
    public func updateColors() {
        self.updateLineColor()
        self.updateTitleColor()
        self.updateTextColor()
    }
    
    private func updateLineColor() {
        if self.hasErrorMessage {
            self.lineView.backgroundColor = self.errorColor
        } else {
            self.lineView.backgroundColor = self.editing ? self.selectedLineColor : self.lineColor
        }
    }
    
    private func updateTitleColor() {
        if self.hasErrorMessage {
            self.titleLabel.textColor = self.errorColor
        } else {
            if self.editing {
                self.titleLabel.textColor = self.selectedTitleColor
            } else {
                self.titleLabel.textColor = self.titleColor
            }
        }
    }
    
    private func updateTextColor() {
        if self.hasErrorMessage {
            self.textField.textColor = self.errorColor
        } else {
            self.textField.textColor = textColor
        }
    }
    
    // MARK: - Title handling
    
    private func updateTitleLabel(animated:Bool = false) {

        if self.hasErrorMessage {
            self.titleLabel.text = self.titleFormatter(errorMessage!)
        } else {
            if self.editing {
                self.titleLabel.text = self.selectedTitleOrPlaceholder()
            } else {
                self.titleLabel.text = self.deselectedTitleOrPlaceholder()
            }
        }
        self.setTitleVisibile(self.hasErrorMessage || self.hasText, animated: animated)
    }

    private func updateTitleVisibility(animated:Bool = false) {
        let alpha:CGFloat = _titleVisible ? 1.0 : 0.0
        let frame:CGRect = self.titleLabelRectForBounds(self.bounds, editing: _titleVisible)
        let updateBlock = { () -> Void in
            self.titleLabel.alpha = alpha
            self.titleLabel.frame = frame
        }
        if animated {
            let duration = _titleVisible ? titleFadeInDuration : titleFadeOutDuration
            UIView.animateWithDuration(duration, animations: { () -> Void in
                updateBlock()
            })
        } else {
            updateBlock()
        }
    }
    
    // MARK: - Positioning Overrides
    
    private func titleLabelRectForBounds(bounds:CGRect) -> CGRect {
        return self.titleLabelRectForBounds(bounds, editing: self.editing)
    }
    
    public func titleLabelRectForBounds(bounds:CGRect, editing:Bool) -> CGRect {

        let titleHeight = self.titleHeight()
        if editing {
            return CGRectMake(0, 0, bounds.size.width, titleHeight)
        } else {
            return CGRectMake(0, titleHeight, bounds.size.width, titleHeight)
        }
    }

    private func lineViewRectForBounds(bounds:CGRect) -> CGRect {
        return self.lineViewRectForBounds(bounds, editing: self.editing)
    }
    
    public func lineViewRectForBounds(bounds:CGRect, editing:Bool) -> CGRect {
        let lineHeight:CGFloat = editing ? CGFloat(self.selectedLineHeight) : CGFloat(self.lineHeight)
        return CGRectMake(0, bounds.size.height - lineHeight, bounds.size.width, lineHeight);
    }
    
    public func textFieldRectForBounds(bounds:CGRect) -> CGRect {
        let titleHeight = self.titleHeight()
        return CGRectMake(0, titleHeight, bounds.size.width, bounds.size.height - titleHeight)
    }
    
    public func placeholderLabelRectForBounds(bounds:CGRect) -> CGRect {
        let titleHeight = self.titleHeight()
        return CGRectMake(0, titleHeight, bounds.size.width, bounds.size.height - titleHeight)
    }
    
    public func titleHeight() -> CGFloat {
        return (self.titleLabel.font?.lineHeight ?? 15.0)
    }
    
    public func textHeight() -> CGFloat {
        return (self.textField.font?.lineHeight ?? 25.0) + 7.0
    }
    
    // MARK: - Textfield delegate methods
    
    public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if let delegate = self.delegate {
            if let result = delegate.textFieldShouldBeginEditing?(self) {
                return result
            }
        }
        return true
    }
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        self.updateControl(true)
        if let delegate = self.delegate {
            delegate.textFieldDidBeginEditing?(self)
        }
    }
    
    public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if let delegate = self.delegate {
            if let result = delegate.textFieldShouldEndEditing?(self) {
                return result
            }
        }
        return true
    }
    
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let delegate = self.delegate {
            if let result = delegate.textField?(self, shouldChangeCharactersInRange: range, replacementString: string) {
                return result
            }
        }
        return true
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        self.updateControl(true)
        if let delegate = self.delegate {
            delegate.textFieldDidEndEditing?(self)
        }
    }

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let delegate = self.delegate {
            if let result = delegate.textFieldShouldReturn?(self) {
                return result
            }
        }
        return true
    }
    
    public func textFieldShouldClear(textField: UITextField) -> Bool {
        if let delegate = self.delegate {
            if let result = delegate.textFieldShouldClear?(self) {
                return result
            }
        }
        return true
    }
    
    // MARK: TextField target actions

    internal func textFieldChanged(textfield: UITextField) {
        self.setText(textField.text, animated: true)
        self.resetErrorMessageIfPresent()
    }
    
    internal func editingDidEndOnExit(textfield: UITextField) {
        self.sendActionsForControlEvents(.EditingDidEndOnExit)
    }
    
    // MARK: Touch handling
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if !self.isFirstResponder() {
            self.becomeFirstResponder()
        }
        
        super.touchesBegan(touches, withEvent: event)
    }
    
    // MARK: - Layout
    
    override public func layoutSubviews() {
        super.layoutSubviews()

        self.placeholderLabel.frame = self.placeholderLabelRectForBounds(self.bounds)
        self.textField.frame = self.textFieldRectForBounds(self.bounds)
        self.lineView.frame = self.lineViewRectForBounds(self.bounds, editing: self.editing)
        self.titleLabel.frame = self.titleLabelRectForBounds(self.bounds, editing: self.hasText)
    }
    
    override public func intrinsicContentSize() -> CGSize {
        return CGSizeMake(self.bounds.size.width, self.titleHeight() + self.textHeight())
    }
    
    // MARK: - Helpers
    
    private func resetErrorMessageIfPresent() {
        if self.hasErrorMessage && discardsErrorMessageOnTextChange {
            self.errorMessage = nil
        }
    }
    
    private func deselectedTitleOrPlaceholder() -> String? {
        if let title = self.deselectedTitle ?? self.placeholder {
            return self.titleFormatter(title)
        }
        return nil
    }
    
    private func selectedTitleOrPlaceholder() -> String? {
        if let title = self.selectedTitle ?? self.placeholder {
            return self.titleFormatter(title)
        }
        return nil
    }
}