//
//  SGInputSelectField.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 09/04/24.
//

import SwiftUI

enum DropDownPickerState {
    case top
    case bottom
}

struct SGInputSelectField: View {
    @Binding var text: String
    var placeholder: String
    var title: String
    var dropDownItem: [String]
    
    var body: some View {
        VStack (alignment: .leading, spacing: 12) {
            Text(title)
              .foregroundColor(Color(.darkGray))
              .fontWeight(.semibold)
              .font(.footnote)

            HStack {
                TextField(placeholder, text: $text)
                  .font(.system(size: 14))
                  .disabled(true)

                Menu {
                    ForEach(dropDownItem, id: \.self){ item in
                        Button(item) {
                            self.text = item
                        }
                        .font(.system(size: 14))
                    }
                } label: {
                    VStack {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                        }
                }

            }
            
            Divider()
        }
    }
}

#Preview {
    SGInputSelectField(text: .constant("Empty"), placeholder: "Enter value", title: "Dropdown", dropDownItem: ["Hello", "World"])
}
