//
//  FilesViewController.swift
//  GCDWebServer (iOS)
//
//  Created by dengw on 2023/4/21.
//

import UIKit

class FilesViewController: UIViewController {
    public var rootPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    public var isPush: Bool = false

    private var files: [String]?
    private var tableView: UITableView?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSubviews()

        NotificationCenter.default.addObserver(self, selector: #selector(webUploaderNeedRefresh(noti:)), name: NSNotification.Name(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    }

    func setupSubviews() {
        view.backgroundColor = .white

        let button = UIButton(frame: CGRectMake(0, 0, 32.0, 24.0))
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(closeButtonAction(sender:)), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)

        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 72.0
        view.addSubview(tableView)
        self.tableView = tableView
    }

    func reloadData() {
        let files = self.files(path: rootPath)
        self.files = files
        tableView?.reloadData()
    }

    @objc func closeButtonAction(sender: UIButton) {
        if isPush == true {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func webUploaderNeedRefresh(noti: Notification) {
        reloadData()

        debugPrint("need refresh files")
    }
}

extension FilesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return (files?.count ?? 0 > 0) ? 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "UITableViewCellId")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCellId")
        }
        let file = files![indexPath.row]
        cell!.textLabel?.text = file.components(separatedBy: "/").last

        let attribute: Dictionary<FileAttributeKey, Any>? = fileAttributes(path: file)
        if isDirectory(path: file) {
            if let attr = attribute {
                let date = attr[FileAttributeKey.modificationDate] as! Date
                cell!.detailTextLabel?.text = String(format: "%@, %@", date.stringIn(format: "HH:mm:ss MM.dd.yyyy"), folderSize(path: file))
            }
            cell?.accessoryType = .disclosureIndicator
        } else {
            if let attr = attribute {
                let date = attr[FileAttributeKey.modificationDate] as! Date
                cell!.detailTextLabel?.text = String(format: "%@, %@", date.stringIn(format: "HH:mm:ss MM.dd.yyyy"), fileSize(filePath: file))
            } else {
                cell!.detailTextLabel?.text = String(format: "%@", fileSize(filePath: file))
            }
            cell?.accessoryType = .none
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let file = files![indexPath.row]
        if isDirectory(path: file) {
            let viewController = FilesViewController()
            viewController.rootPath = file
            viewController.title = file.components(separatedBy: "/").last
            viewController.isPush = true
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension FilesViewController {
    func files(path: String) -> [String]? {
        var results: [String] = [String]()
        let files = try! FileManager.default.contentsOfDirectory(atPath: path)
        for file in files {
            if file.contains(".DS_Store") {
                continue
            }

            let filePath = path + "/\(file)"
            results.append(filePath)
        }
        return results
    }

    func directoryIsExists(path: String) -> Bool {
        var directoryExists = ObjCBool(false)
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        return fileExists && directoryExists.boolValue
    }

    func folderSize(path: String) -> String {
        guard directoryIsExists(path: path) else {
            return ""
        }

        guard FileManager.default.fileExists(atPath: path) else {
            return ""
        }

        var fileSize: UInt64 = 0 // bytes
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in files {
                if file.contains(".DS_Store") {
                    continue
                }

                let filePath = path + "/\(file)"
                fileSize = fileSize + fileSizeBytes(filePath: filePath)
            }
        } catch {
            debugPrint("遍历文件夹内容出错")
        }

        if fileSize <= 0 {
            return ""
        }
        return bytesToSize(length: fileSize)
    }

    func fileSizeBytes(filePath: String) -> UInt64 {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return 0
        }
        guard let dic = try? FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary else {
            return 0
        }
        let bytes: UInt64 = dic.fileSize()
        return bytes
    }

    func fileSize(filePath: String) -> String {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return ""
        }
        guard let dic = try? FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary else {
            return ""
        }
        let bytes: UInt64 = dic.fileSize()
        return bytesToSize(length: bytes)
    }

    func bytesToSize(length: UInt64) -> String {
        let units = ["Byte", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        var dataLength: Double = Double(length)
        var index: Int = 0
        while dataLength > 1024.0 {
            dataLength = dataLength / 1024.0
            index = index + 1
        }
        return "\(dataLength.stripZero) \(units[index])"
    }

    func isDirectory(path: String) -> Bool {
        var directoryExists = ObjCBool(false)
        _ = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        return directoryExists.boolValue
    }

    func fileAttributes(path: String) -> Dictionary<FileAttributeKey, Any>? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes
    }
}

extension Date {
    public func stringIn(format: String = "MM_dd_yyyy_HH:mm:ss", timeZone: TimeZone = TimeZone.current, locale: Locale = Locale.current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = locale // Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone // TimeZone(secondsFromGMT: 0)

        return dateFormatter.string(from: self)
    }
}

extension Double {
    /// 去除无效 0。 小数点后如果只是0，显示整数，如果不是，显示小数点后2位的值
    var stripZero: String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.2f", self)
    }
}
