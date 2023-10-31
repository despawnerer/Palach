import Foundation
import NeonPlugin
import STTextView
import SwiftUI
import TextFormation
import TextFormationPlugin

struct CodeEditorView: SwiftUI.View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var text: String
    @Binding var selection: NSRange?

    init(
        text: Binding<String>,
        selection: Binding<NSRange?> = .constant(nil)
    ) {
        _text = text
        _selection = selection
    }

    var body: some View {
        TextViewRepresentable(
            text: $text,
            selection: $selection
        )
        .background(.background)
    }
}

struct TextViewRepresentable: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.font) private var font
    @Environment(\.lineSpacing) private var lineSpacing

    @Binding var text: String
    @Binding var selection: NSRange?

    init(text: Binding<String>, selection: Binding<NSRange?>) {
        _text = text
        _selection = selection
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = STTextView()
        let scrollView = NSScrollView()
        scrollView.documentView = textView

        textView.highlightSelectedLine = true
        textView.widthTracksTextView = true
        textView.setSelectedRange(NSRange())
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        textView.isIncrementalSearchingEnabled = true
        textView.textFinder.incrementalSearchingShouldDimContentView = true

        textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))

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

        textView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! STTextView

        guard !context.coordinator.isReactingToChangeFromInternalView else {
            context.coordinator.isReactingToChangeFromInternalView = false
            return
        }

        context.coordinator.isUpdatingFromSwiftUI = true

        textView.setAttributedString(NSAttributedString(styledAttributedString(textView.typingAttributes)))

        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }

        if textView.isSelectable != isEnabled {
            textView.isSelectable = isEnabled
        }

        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        context.coordinator.isUpdatingFromSwiftUI = false
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
            var styledText = AttributedString(text)
            styledText.mergeAttributes(attributeContainer, mergePolicy: .keepNew)
            return styledText
        }

        return AttributedString(text)
    }

    class TextCoordinator: STTextViewDelegate {
        var parent: TextViewRepresentable
        var isUpdatingFromSwiftUI: Bool = false
        var isReactingToChangeFromInternalView: Bool = false

        init(parent: TextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChangeText(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI else {
                return
            }

            guard let textView = notification.object as? STTextView else {
                return
            }

            isReactingToChangeFromInternalView = true
            parent.text = textView.attributedString().string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI else {
                return
            }

            guard let textView = notification.object as? STTextView else {
                return
            }

            isReactingToChangeFromInternalView = true
            parent.selection = textView.selectedRange()
        }
    }
}
