//  Created by Marcin Krzyzanowski
//  https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md

import Foundation
import NeonPlugin
import STTextView
import SwiftUI
import TextFormation
import TextFormationPlugin

public struct CodeEditorView: SwiftUI.View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?

    /// Create a text edit view with a certain text that uses a certain options.
    /// - Parameters:
    ///   - text: The attributed string content
    public init(
        text: Binding<AttributedString>,
        selection: Binding<NSRange?> = .constant(nil)
    ) {
        _text = text
        _selection = selection
    }

    public var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection
        )
        .background(.background)
    }
}

private struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.font) private var font
    @Environment(\.lineSpacing) private var lineSpacing

    @Binding private var text: AttributedString
    @Binding private var selection: NSRange?

    init(text: Binding<AttributedString>, selection: Binding<NSRange?>) {
        _text = text
        _selection = selection
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = STTextView()
        let scrollView = NSScrollView()
        scrollView.documentView = textView

        textView.delegate = context.coordinator
        textView.highlightSelectedLine = true
        textView.widthTracksTextView = true
        textView.setSelectedRange(NSRange())
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        textView.isIncrementalSearchingEnabled = true
        textView.textFinder.incrementalSearchingShouldDimContentView = true

        context.coordinator.isUpdating = true
        textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))
        context.coordinator.isUpdating = false

        // Line numbers: Should be after setting font
        let rulerView = STLineNumberRulerView(textView: textView)
        rulerView.highlightSelectedLine = true
        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        textView.addPlugin(NeonPlugin(theme: .default, language: .swift))
        textView.addPlugin(TextFormationPlugin(
            filters: [
                StandardOpenPairFilter(open: "[", close: "]"),
                StandardOpenPairFilter(open: "{", close: "}"),
                StandardOpenPairFilter(open: "<", close: ">"),
                NewlineProcessingFilter(),
            ],
            whitespaceProviders: WhitespaceProviders(
                leadingWhitespace: TextualIndenter().substitionProvider(indentationUnit: "    ", width: 4),
                trailingWhitespace: WhitespaceProviders.removeAllProvider
            )
        ))

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        let textView = scrollView.documentView as! STTextView

        do {
            context.coordinator.isUpdating = true
            if context.coordinator.isDidChangeText == false {
                textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))
            }
            context.coordinator.isUpdating = false
            context.coordinator.isDidChangeText = false
        }

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
        }

        // FIXME: Not entirely sure what this does?
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    }

    func makeCoordinator() -> TextCoordinator {
        TextCoordinator(parent: self)
    }

    private func styledAttributedString(_ typingAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        let paragraph = (typingAttributes[.paragraphStyle] as! NSParagraphStyle).mutableCopy() as! NSMutableParagraphStyle
        if paragraph.lineSpacing != lineSpacing {
            paragraph.lineSpacing = lineSpacing
            var typingAttributes = typingAttributes
            typingAttributes[.paragraphStyle] = paragraph

            let attributeContainer = AttributeContainer(typingAttributes)
            var styledText = text
            styledText.mergeAttributes(attributeContainer, mergePolicy: .keepNew)
            return styledText
        }

        return text
    }

    class TextCoordinator: STTextViewDelegate {
        var parent: TextViewRepresentable
        var isUpdating: Bool = false
        var isDidChangeText: Bool = false
        var enqueuedValue: AttributedString?

        init(parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            if !isUpdating {
                let newTextValue = AttributedString(textView.attributedString())
                DispatchQueue.main.async {
                    self.isDidChangeText = true
                    self.parent.text = newTextValue
                }
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? STTextView else {
                return
            }

            Task { @MainActor in
                self.isDidChangeText = true
                self.parent.selection = textView.selectedRange()
            }
        }
    }
}
