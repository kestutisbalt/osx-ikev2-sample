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
	
	let vpnManager = NEVPNManager.sharedManager()
	let notificationCenter = NSNotificationCenter.defaultCenter()
	
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		notificationCenter.addObserver(self,
			selector: #selector(AppDelegate.onVpnStateChange(_:)),
			name: NEVPNStatusDidChangeNotification, object: nil)
		
		btnDisconnect.enabled = false
	}

	
	func applicationWillTerminate(aNotification: NSNotification) {
		notificationCenter.removeObserver(self)
	}
	
	
	@IBAction func onConnectClick(sender: NSButton) {
		let host = getHost()
		let username = getUsername()
		let password = getPassword()
		
		let ikev2Protocol = createIKEv2Protocol(host, username: username,
			password: password)

		btnConnect.enabled = false
		connect(ikev2Protocol)
	}
	
	
	@IBAction func onDisconnectClick(sender: NSButton) {
		vpnManager.connection.stopVPNTunnel()
		btnDisconnect.enabled = false
	}
	
	
	private func connect(vpnProtocol: NEVPNProtocol) {
		vpnManager.loadFromPreferencesWithCompletionHandler {
			(error: NSError?) in
			
			self.vpnManager.protocolConfiguration = vpnProtocol
			self.vpnManager.enabled = true
			
			self.vpnManager.saveToPreferencesWithCompletionHandler {
				(error: NSError?) in
				do {
					try self.vpnManager.connection.startVPNTunnel()
				} catch let error as NSError {
					self.log("Error: \(error.localizedDescription)")
				}
			}
		}
	}
	
	
	private func log(msg: String) {
		dispatch_async(dispatch_get_main_queue()) {
			self.txtLog?.textStorage?.appendAttributedString(
				NSAttributedString(string: "\(NSDate()):\t\(msg)\n"))
		}
	}
	
	
	private func getUsername() -> String {
		let username = txtUsername?.stringValue
		if username != nil {
			return username!
		}
		
		return ""
	}
	
	
	private func getHost() -> String {
		let host = txtHost?.stringValue
		if host != nil {
			return host!
		}
		
		return ""
	}

	
	private func getPassword() -> String {
		let password = txtPassword?.stringValue
		if password != nil {
			return password!
		}
		
		return ""
	}

	
	private func createIKEv2Protocol(host: String,
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
	
	
	func onVpnStateChange(notification: NSNotification) {
		let state = vpnManager.connection.status
		
		var host = vpnManager.protocolConfiguration?.serverAddress
		if host == nil {
			host = "Unknown"
		}
		
		switch state {
		case .Connecting:
			log("Connecting to \(host!)")
			break
		case .Connected:
			log("Connected to \(host!)")
			break
		case .Disconnecting:
			log("Disconnecting from \(host!)")
			break
		case .Disconnected:
			log("Disconnected from \(host!)")
			break
		case .Invalid:
			log("Invalid")
			break
		case .Reasserting:
			log("Reasserting")
			break
		}
		
		if state == .Connecting || state == .Connected
			|| state == .Reasserting {
		
			btnDisconnect.enabled = true
			btnConnect.enabled = false
		} else if state == .Disconnected || state == .Disconnecting
			|| state == .Invalid {
			
			btnDisconnect.enabled = false
			btnConnect.enabled = true
		}
	}
}