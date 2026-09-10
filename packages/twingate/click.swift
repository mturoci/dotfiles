// Real HID-level mouse events. Twingate's menu ignores AX actions and
// System Events' "click at", so interaction has to reach the event tap.
//
//   click pos                       -> prints "x y" of the cursor
//   click move  <x> <y>             -> moves the cursor (opens submenus on hover)
//   click click <x> <y> [<rx> <ry>] -> clicks, optionally restoring the cursor
import CoreGraphics
import Foundation

let src = CGEventSource(stateID: .hidSystemState)

func post(_ type: CGEventType, _ pt: CGPoint) {
    CGEvent(mouseEventSource: src, mouseType: type, mouseCursorPosition: pt, mouseButton: .left)?
        .post(tap: .cghidEventTap)
}

func die(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(2)
}

let a = CommandLine.arguments
guard a.count >= 2 else { die("usage: click pos|move|click ...") }

switch a[1] {
case "pos":
    guard let l = CGEvent(source: nil)?.location else { die("cannot read cursor") }
    print("\(l.x) \(l.y)")

case "move":
    guard a.count == 4, let x = Double(a[2]), let y = Double(a[3]) else { die("usage: click move <x> <y>") }
    post(.mouseMoved, CGPoint(x: x, y: y))

case "click":
    guard a.count >= 4, let x = Double(a[2]), let y = Double(a[3]) else { die("usage: click click <x> <y> [<rx> <ry>]") }
    let pt = CGPoint(x: x, y: y)
    post(.mouseMoved, pt)
    usleep(150_000)
    post(.leftMouseDown, pt)
    usleep(80_000)
    post(.leftMouseUp, pt)
    if a.count == 6, let rx = Double(a[4]), let ry = Double(a[5]) {
        usleep(120_000)
        post(.mouseMoved, CGPoint(x: rx, y: ry))
    }

default:
    die("unknown subcommand: \(a[1])")
}
