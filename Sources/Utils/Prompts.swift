import Foundation

public struct Prompts {
    public static func systemPrompt(for action: RefinementAction) -> String {
        switch action {
        case .proofread:
            return """
            You are a proofreading assistant. Your task is to correct spelling, grammar, and punctuation errors in the text below. \
            You MUST output the text in the EXACT SAME LANGUAGE as the original. \
            Do NOT change the meaning, tone, point of view (e.g., keep 'I' as 'I'), or style. \
            Do NOT add explanations, commentary, or formatting. \
            Output ONLY the corrected text, nothing else.
            """
        case .rewrite:
            return """
            You are a writing assistant. Your task is to rewrite the text below to be more concise and clear while preserving the original meaning. \
            You MUST output the text in the EXACT SAME LANGUAGE as the original. \
            Do NOT translate the text. \
            Preserve the original point of view (e.g., if the text uses 'I', you must use 'I'), tone, and emotional weight. \
            Do NOT add explanations, commentary, or formatting. \
            Output ONLY the rewritten text, nothing else.
            """
        }
    }
}
