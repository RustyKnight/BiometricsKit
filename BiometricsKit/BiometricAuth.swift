//
//  BiometricAuth.swift
//  BeamBiometricsKit
//
//  Created by Shane Whitehead on 16/10/18.
//  Copyright © 2018 BeamCommunications. All rights reserved.
//

import Foundation
import LocalAuthentication

public enum BiometryError: Error {
	case lockedOut
	case notAvaliable
}

public enum BiometrySupport {
	public enum Biometry {
		case touchID
		case faceID
	}
	
	case available(Biometry)
	case lockedOut(Biometry)
	case notAvailable(Biometry)
	case none
	
	public var biometry: Biometry? {
		switch self {
		case .none, .lockedOut, .notAvailable:
			return nil
		case let .available(biometry):
			return biometry
		}
	}
}

public final class BiometricAuth {
	
	public var supportedBiometry: BiometrySupport {
		let context = LAContext()
		var error: NSError?
		
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			if #available(iOS 11.0, *) {
				switch context.biometryType {
				case .faceID:
					return .available(.faceID)
				case .touchID:
					return .available(.touchID)
					// NOTE: LABiometryType.none was introduced in iOS 11.2
					// which is why it can't be used here even though Xcode
				// errors with "non-exhaustive switch" if you don't use it 🤷🏼‍♀️
				default:
					return .none
				}
			}
			
			return .available(.touchID)
		}
		
		// NOTE: despite what Apple Docs state, the biometryType
		// property *is* set even if canEvaluatePolicy fails
		// See: http://www.openradar.me/36064151
		if let error = error {
			let code = LAError(_nsError: error as NSError).code
			if #available(iOS 11.0, *) {
				switch (code, context.biometryType) {
				case (.biometryLockout, .faceID):
					return .lockedOut(.faceID)
				case (.biometryLockout, .touchID):
					return .lockedOut(.touchID)
				case (.biometryNotAvailable, .faceID), (.biometryNotEnrolled, .faceID):
					return .notAvailable(.faceID)
				case (.biometryNotAvailable, .touchID), (.biometryNotEnrolled, .touchID):
					return .notAvailable(.touchID)
				default:
					return .none
				}
			} else {
				switch code {
				case .touchIDLockout:
					return .lockedOut(.touchID)
				case .touchIDNotEnrolled, .touchIDNotAvailable:
					return .notAvailable(.touchID)
				default:
					return .none
				}
			}
		}
		
		return .none
	}
	
	public func performAuthentication(then: @escaping (Bool, Error?) -> Void) {
		switch supportedBiometry {
		case .available(.faceID): fallthrough
		case .available(.touchID):
			let context = LAContext()
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate user account", reply: then)
			//      context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate user account") { (success, error) in
			//        if (success) {
			//          print("Authorization successful")
			//        } else if let error = error {
			//          print("Authorization failed: \(error)")
			//        } else {
			//          print("Authorization failed for unknown reason")
			//        }
		//      }
		case .none: print("Not supported")
		case .lockedOut(.faceID): fallthrough
		case .lockedOut(.touchID):
			then(false, BiometryError.lockedOut)
		case .notAvailable(.touchID): fallthrough
		case .notAvailable(.faceID):
			then(false, BiometryError.notAvaliable)
		}
	}
	
	// create an Access Control
//	static func createAccessControl() -> SecAccessControl? {
//		var accessControlError: Unmanaged<CFError>?
//		
//		var flags = [SecAccessControlCreateFlags.biometryAny]
//		
//		guard let accessControl = SecAccessControlCreateWithFlags(
//			kCFAllocatorDefault,
//			kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//			[SecAccessControlCreateFlags.biometryCurrentSet], &accessControlError) else {
//				// couldn't create accessControl
//				print("Could not create access control")
//				return nil
//		}
//		
//		return accessControl
//	}
	
	//  let query: [String: Any] = [
	//    kSecClass as String: kSecClassGenericPassword,
	//    kSecAttrService as String: "my service name",
	//    kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
	//    kSecValueData as String: "my secret data",
	//    kSecAttrAccessControl as String: accessControl,
	//    ]
	//
	//  SecItemAdd(query as CFDictionary, nil)
}
