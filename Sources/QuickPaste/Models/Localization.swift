import Foundation
import SwiftUI

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case vi = "Tiếng Việt"
    case en = "English"
    var id: String { self.rawValue }
}

class Localization {
    static let shared = Localization()

    private let dictionary: [String: [AppLanguage: String]] = [
        "menu_open": [.vi: "Mở", .en: "Open"],
        "menu_settings": [.vi: "⚙️ Cài đặt…", .en: "⚙️ Settings…"],
        "menu_quit": [.vi: "Thoát", .en: "Quit"],

        "tab_snippets": [.vi: "Snippets", .en: "Snippets"],
        "tab_quick_action": [.vi: "Quick Action", .en: "Quick Action"],
        "tab_clipboard": [.vi: "Clipboard", .en: "Clipboard"],
        "tab_general": [.vi: "Chung", .en: "General"],

        "manage_snippets": [.vi: "Quản lý Snippets", .en: "Manage Snippets"],
        "add": [.vi: "Thêm", .en: "Add"],
        "reset": [.vi: "Khôi phục", .en: "Reset"],
        "add_snippet": [.vi: "Thêm Snippet mới", .en: "Add New Snippet"],
        "edit_snippet": [.vi: "Chỉnh sửa Snippet", .en: "Edit Snippet"],
        
        "name": [.vi: "Tên:", .en: "Name:"],
        "category": [.vi: "Danh mục:", .en: "Category:"],
        "content": [.vi: "Nội dung:", .en: "Content:"],
        "cancel": [.vi: "Huỷ", .en: "Cancel"],
        "save": [.vi: "Lưu", .en: "Save"],

        "manage_qa": [.vi: "Quản lý Quick Actions", .en: "Manage Quick Actions"],
        "add_qa": [.vi: "Thêm Quick Action", .en: "Add Quick Action"],
        "edit_qa": [.vi: "Chỉnh sửa Quick Action", .en: "Edit Quick Action"],
        "icon_emoji": [.vi: "Icon (Emoji):", .en: "Icon (Emoji):"],
        "display_name": [.vi: "Tên hiển thị:", .en: "Display Name:"],
        "paste_content": [.vi: "Nội dung Paste:", .en: "Paste Content:"],

        "shortcuts": [.vi: "Phím tắt (Shortcuts)", .en: "Shortcuts"],
        "open_snippets": [.vi: "Mở Snippets:", .en: "Open Snippets:"],
        "open_clipboard": [.vi: "Mở Clipboard:", .en: "Open Clipboard:"],

        "launch_at_login": [.vi: "Khởi động cùng macOS", .en: "Launch at login"],

        "display": [.vi: "Hiển thị", .en: "Display"],
        "show_snippets": [.vi: "Hiện Snippets trong Popup", .en: "Show Snippets in Popup"],
        "show_clipboard": [.vi: "Hiện Clipboard trong Popup", .en: "Show Clipboard in Popup"],
        
        "clipboard_history": [.vi: "Lịch sử Clipboard", .en: "Clipboard History"],
        "max_items": [.vi: "Số lượng tối đa:", .en: "Maximum items:"],
        
        "info": [.vi: "Thông tin", .en: "Information"],
        "language": [.vi: "Ngôn ngữ:", .en: "Language:"],

        "search": [.vi: "Tìm kiếm…", .en: "Search…"],
        "no_snippets": [.vi: "Không có snippet", .en: "No snippets"],
        "empty": [.vi: "Trống", .en: "Empty"],
        "move": [.vi: "Di chuyển", .en: "Move"],
        "select": [.vi: "Chọn", .en: "Select"],
        "quick": [.vi: "Chọn nhanh", .en: "Quick"],
        "settings": [.vi: "Cài đặt", .en: "Settings"],
        "error_no_display": [.vi: "Vui lòng bật hiển thị Snippets hoặc Clipboard", .en: "Please enable Snippets or Clipboard"],
        "clear_clipboard": [.vi: "Xoá lịch sử", .en: "Clear History"],
        "save_to_snippets": [.vi: "Lưu vào Snippets", .en: "Save to Snippets"],
        "save_to_qa": [.vi: "Lưu vào Quick Actions", .en: "Save to Quick Actions"],
        "delete": [.vi: "Xoá", .en: "Delete"],
        "close": [.vi: "Đóng", .en: "Close"],

        "time_just_now": [.vi: "vừa xong", .en: "just now"],
        "time_minutes_ago": [.vi: "%d phút trước", .en: "%d min ago"],
        "time_hours_ago": [.vi: "%d giờ trước", .en: "%d hr ago"],
        "time_days_ago": [.vi: "%d ngày trước", .en: "%d days ago"]
    ]

    func t(_ key: String, lang: AppLanguage) -> String {
        return dictionary[key]?[lang] ?? key
    }
}

func tr(_ key: String, lang: AppLanguage) -> String {
    return Localization.shared.t(key, lang: lang)
}
