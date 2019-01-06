//
//  BiometricService.swift
//  BeamBiometricsKit
//
//  Created by Shane Whitehead on 16/10/18.
//  Copyright © 2018 BeamCommunications. All rights reserved.
//

import Foundation
import Hydra
import KeychainAccess
import Cadmus

public class BiometricService {
	public static let shared: BiometricService = BiometricService()
	
	struct Keys {
		static let useBiometrics = "Key.useBiometrics"
		static let keyChainBiometricService = "Key.loginKeychainService"
		static let keyChainProperty = "Key.loginKeychainLogin"
	}
	
	public var hasBiometricSupport: Bool {
		let ba = BiometricAuth()
		switch ba.supportedBiometry {
		case .available(.faceID): fallthrough
		case .available(.touchID): return true
		default: return false
		}
	}
	
	public var hasBiometricCredentials: Bool {
		let defaults = UserDefaults.standard
		return defaults.bool(forKey: Keys.useBiometrics)
	}
	
	fileprivate init() {}
	
//	public func authenticate(credentials: Credentials, prompt: String, save: Bool = true) -> Promise<Void> {
//		return Promise<Void>(in: .userInitiated, { (fulfill, fail, _) in
//			// Should this return something or can we assume if
//			// it didn't throw an error, authentication worked
//			fulfill(())
//		}).defer(5.0)
//			.then { () -> Promise<Void> in
//				guard save else {
//					return Promise<Void>(resolved: ())
//				}
//				try self.save(credentials: credentials, prompt: prompt)
//				return Promise<Void>(resolved: ())
//		}
//	}
	
	public func save(_ data: Data, prompt: String) throws {
		let defaults = UserDefaults.standard
		let ba = BiometricAuth()
		switch ba.supportedBiometry {
		case .available(.faceID): fallthrough
		case .available(.touchID):
			let keyChain = Keychain(service: Keys.keyChainBiometricService)
			log(debug: "Store credentials in key chain")
			keyChain.set(data, forKey: Keys.keyChainProperty, withPrompt: prompt)
				.then(in: .main) { () in
					log(debug: "Sert biometrics key true")
					defaults.set(true, forKey: Keys.useBiometrics)
					defaults.synchronize()
				}.catch(in: .main) { (error) in
					defaults.set(false, forKey: Keys.useBiometrics)
					defaults.synchronize()
			}
		default:
			log(warning: "No biometric support avaliable")
			break
		}
	}
	
	public func loadCredentials(prompt: String) -> Promise<Data?> {
		log(debug: "hasBiometricSupport = \(hasBiometricSupport)")
		log(debug: "hasBiometricCredentials = \(hasBiometricCredentials)")
		guard hasBiometricSupport && hasBiometricCredentials else {
			return Promise<Data?>(resolved: nil)
		}
		let ba = BiometricAuth()
		switch ba.supportedBiometry {
		case .available(.faceID): fallthrough
		case .available(.touchID):
			let keyChain = Keychain(service: Keys.keyChainBiometricService)
			return keyChain.authenticate(withPrompt: prompt,
																	 forKey: Keys.keyChainProperty)
//				.then(in: .main) { (json) -> Promise<Data?> in
//					log(debug: "json = \(String(describing: json))")
//					guard let json = json, let data = json.data(using: .utf8) else {
//						return Promise<Data?>(resolved: nil)
//					}
//					let decoder = JSONDecoder()
//					let credentials = try decoder.decode(credentialsType, from: data)
//					log(debug: "credentials = \(credentials)")
//					return Promise<Data?>(resolved: credentials)
//		}
		default:
			return Promise<Data?>(resolved: nil)
		}
	}
	
	public func remove() throws {
		let defaults = UserDefaults.standard
		defaults.set(false, forKey: Keys.useBiometrics)
		defaults.synchronize()
		let keyChain = Keychain(service: Keys.keyChainBiometricService)
		try keyChain.remove(Keys.keyChainProperty)
	}
	
	func logout() -> Promise<Void> {
		return Promise<Void>(in: .main, { (fulfill, fail, _) in
			try self.remove()
			fulfill(())
		})
	}
}
