//
//  SGInputTextField.swift
//  Segment3D
//
//  Created by I Made Indra Mahaarta on 31/03/24.
//

import SwiftUI

struct SGInputTextField: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecuredPassword = false
    var isAutoCapitalize = TextInputAutocapitalization.never
    var onChange: (String) -> Void = { _ in }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: {
            Text(title)
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.footnote)
            if isSecuredPassword {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .onChange(of: text) { oldValue, newValue in
                        onChange(newValue)
                    }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(isAutoCapitalize)
                    .onChange(of: text) { oldValue, newValue in
                        onChange(newValue)
                    }
            }
            Divider()
        })
    }
}

#Preview {
    SGInputTextField(text: .constant(""), title: "Password", placeholder: "Enter your password", isSecuredPassword: true)
}
