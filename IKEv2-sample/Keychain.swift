import Foundation
import Security


class Keychain {

	class func persistentRef(_ key: String) -> Data? {
		let query: [AnyHashable: Any] = [
			kSecClass as AnyHashable: kSecClassGenericPassword,
			kSecAttrGeneric as AnyHashable: key,
			kSecAttrAccount as AnyHashable: key,
			kSecAttrAccessible as AnyHashable: kSecAttrAccessibleAlways,
			kSecMatchLimit as AnyHashable: kSecMatchLimitOne,
			kSecAttrService as AnyHashable: Bundle.main.bundleIdentifier!,
			kSecReturnPersistentRef as AnyHashable: kCFBooleanTrue
		]
		
		var secItem: AnyObject?
		let result = SecItemCopyMatching(query as CFDictionary, &secItem)
		if result != errSecSuccess {
			return nil
		}
		
		return secItem as? Data
	}
	

	class func set(_ key: String, value: String) {
		
		let query: [AnyHashable: Any] = [
			kSecValueData as AnyHashable: value.data(using: String.Encoding.utf8)!,
			kSecClass as AnyHashable: kSecClassGenericPassword,
			kSecAttrGeneric as AnyHashable: key,
			kSecAttrAccount as AnyHashable: key,
			kSecAttrAccessible as AnyHashable: kSecAttrAccessibleAlways,
			kSecAttrService as AnyHashable: Bundle.main.bundleIdentifier!
		]

		clear(key)
		SecItemAdd(query as CFDictionary, nil)
	}


	class func clear(_ key: String) {
		let query: [AnyHashable: Any] = [
			kSecClass as AnyHashable: kSecClassGenericPassword,
			kSecAttrAccount as AnyHashable: key
		]
		SecItemDelete(query as CFDictionary)
	}
}
