//
//  LocalizationHelper.swift
//  Selene
//
//  Created by True砖家 on 2024/7/23.
//  Copyright © True砖家 on Bilibili. All rights reserved.
//

extension LocalizationHelper {
    static func localizedString(forKey key: String, _ args: CVarArg...) -> String {
        let format = localizedFormat(forKey: key)
        return String(format: format, arguments: args)
    }
}
