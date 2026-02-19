//
//  DayNoteNestSheet.swift
//  parents
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI

struct DayNoteNestSheet: View {

    @ObservedObject var brain: CradleDayBrain
    @Environment(\.dismiss) private var dismiss
    @State private var noteText: String = ""

    var body: some View {
        ZStack {
            NestPalette.midnightNest.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Day Note")
                                .font(NestTypography.guardianHeadline)
                                .foregroundColor(NestPalette.parentVoice)

                            Spacer()

                            Button { dismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(NestPalette.drowsyHint)
                            }
                        }

                        TextEditor(text: $noteText)
                            .font(NestTypography.lullabyBody)
                            .foregroundColor(NestPalette.parentVoice)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                                    .fill(NestPalette.sleepyCharcoal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NestDimensions.cradleCorner)
                                            .stroke(NestPalette.dreamlineDivider, lineWidth: 1)
                                    )
                            )
                            .id("noteEditor")

                        Button {
                            brain.saveDayNote(noteText)
                            dismiss()
                        } label: {
                            Text("Save Note")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NestPrimaryButtonStyle())

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    init(brain: CradleDayBrain) {
        self.brain = brain
        _noteText = State(initialValue: brain.dayNote)
    }
}

