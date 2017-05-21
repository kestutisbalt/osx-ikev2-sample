import Cocoa
import NetworkExtension


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var btnConnect: NSButton!
	@IBOutlet weak var btnDisconnect: NSButton!
	@IBOutlet var txtLog: NSTextView!
	@IBOutlet weak var txtHost: NSTextField!
	@IBOutlet weak var txtUsername: NSTextField!
	@IBOutlet weak var txtPassword: NSSecureTextField!
	
	let vpnManager = NEVPNManager.shared()
	let notificationCenter = NotificationCenter.default
	
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		notificationCenter.addObserver(self,
			selector: #selector(AppDelegate.onVpnStateChange(_:)),
			name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
		
		btnDisconnect.isEnabled = false
	}

	
	func applicationWillTerminate(_ aNotification: Notification) {
		notificationCenter.removeObserver(self)
	}
	
	
	@IBAction func onConnectClick(_ sender: NSButton) {
		let host = getHost()
		let username = getUsername()
		let password = getPassword()
		
		let ikev2Protocol = createIKEv2Protocol(host, username: username,
			password: password)

		btnConnect.isEnabled = false
		connect(ikev2Protocol)
	}
	
	
	@IBAction func onDisconnectClick(_ sender: NSButton) {
		vpnManager.connection.stopVPNTunnel()
		btnDisconnect.isEnabled = false
	}
	
	
	fileprivate func connect(_ vpnProtocol: NEVPNProtocol) {
		vpnManager.loadFromPreferences {
			(error: Error?) in
			
			self.vpnManager.protocolConfiguration = vpnProtocol
			self.vpnManager.isEnabled = true
			
			self.vpnManager.saveToPreferences {
				(error: Error?) in
				do {
					try self.vpnManager.connection.startVPNTunnel()
				} catch let error as NSError {
					self.log("Error: \(error.localizedDescription)")
				}
			}
		}
	}
	
	
	fileprivate func log(_ msg: String) {
		DispatchQueue.main.async {
			self.txtLog?.textStorage?.append(
				NSAttributedString(string: "\(Date()):\t\(msg)\n"))
		}
	}
	
	
	fileprivate func getUsername() -> String {
		let username = txtUsername?.stringValue
		if username != nil {
			return username!
		}
		
		return ""
	}
	
	
	fileprivate func getHost() -> String {
		let host = txtHost?.stringValue
		if host != nil {
			return host!
		}
		
		return ""
	}

	
	fileprivate func getPassword() -> String {
		let password = txtPassword?.stringValue
		if password != nil {
			return password!
		}
		
		return ""
	}

	
	fileprivate func createIKEv2Protocol(_ host: String,
		username: String, password: String) -> NEVPNProtocolIKEv2 {
	
		Keychain.set(username, value: password)
		let passwordRef = Keychain.persistentRef(username)
		if passwordRef == nil {
			log("Failed to query password persistent ref")
		}
		
		let config = NEVPNProtocolIKEv2()
		
		config.remoteIdentifier = host
		config.serverAddress = host
		config.useExtendedAuthentication = true
		config.username = username
		config.passwordReference = passwordRef
		
		return config
	}
	
	
	func onVpnStateChange(_ notification: Notification) {
		let state = vpnManager.connection.status
		
		var host = vpnManager.protocolConfiguration?.serverAddress
		if host == nil {
			host = "Unknown"
		}
		
		switch state {
		case .connecting:
			log("Connecting to \(host!)")
			break
		case .connected:
			log("Connected to \(host!)")
			break
		case .disconnecting:
			log("Disconnecting from \(host!)")
			break
		case .disconnected:
			log("Disconnected from \(host!)")
			break
		case .invalid:
			log("Invalid")
			break
		case .reasserting:
			log("Reasserting")
			break
		}
		
		if state == .connecting || state == .connected
			|| state == .reasserting {
		
			btnDisconnect.isEnabled = true
			btnConnect.isEnabled = false
		} else if state == .disconnected || state == .disconnecting
			|| state == .invalid {
			
			btnDisconnect.isEnabled = false
			btnConnect.isEnabled = true
		}
	}
}
