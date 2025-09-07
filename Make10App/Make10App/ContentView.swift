import SwiftUI

enum Difficulty {
    case easy, normal, hard
}

struct ContentView: View {
    @State private var selectedDifficulty: Difficulty? = nil

    var body: some View {
        if let difficulty = selectedDifficulty {
            GameView(difficulty: difficulty, onHome: { selectedDifficulty = nil })
        } else {
            HomeView { diff in
                selectedDifficulty = diff
            }
        }
    }
}

struct HomeView: View {
    var onSelect: (Difficulty) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Text("MAKE 10")
                .font(.largeTitle)
                .bold()

            Text("Select Difficulty")
                .font(.title2)

            VStack(spacing: 20) {
                Button("EASY") { onSelect(.easy) }
                    .font(.title)
                    .frame(width: 200, height: 60)
                    .buttonStyle(.borderedProminent)

                Button("NORMAL") { onSelect(.normal) }
                    .font(.title)
                    .frame(width: 200, height: 60)
                    .buttonStyle(.borderedProminent)

                Button("HARD") { onSelect(.hard) }
                    .font(.title)
                    .frame(width: 200, height: 60)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct GameView: View {
    var difficulty: Difficulty
    var onHome: () -> Void

    @State private var expression: String = ""
    @State private var numbers: [Int] = [1, 2, 3, 4]
    @State private var used: [Bool] = [false, false, false, false]
    @State private var result: String = "Let's play!"
    @State private var lastWasNumber: Bool? = nil

    var allNumbersUsed: Bool {
        used.allSatisfy { $0 }
    }

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            HStack {
                Button("🏠 Home") { onHome() }
                    .buttonStyle(.bordered)

                Spacer()
                Text("\(difficultyLabel()) Mode")
                    .font(.headline)
            }
            .padding(.horizontal)

            // 上部: 式と評価
            VStack(spacing: 10) {
                Text("Your Expression:")
                    .font(.headline)
                Text(expression.isEmpty ? "Tap buttons below!" : expression)
                    .font(.title)
                Text(result)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding()

            // 演算子 & 括弧
            VStack(spacing: 15) {
                Text("Operators")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(["(", ")", "+", "-", "×", "÷"], id: \.self) { op in
                        Button(op) { handleOperator(op) }
                            .font(.title)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(.horizontal)

            // 数字ボタン
            VStack(spacing: 15) {
                Text("Numbers")
                    .font(.headline)
                HStack(spacing: 20) {
                    ForEach(0..<numbers.count, id: \.self) { i in
                        Button("\(numbers[i])") {
                            handleNumber(numbers[i], index: i)
                        }
                        .disabled(used[i])
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .buttonStyle(.bordered)
                    }
                }
            }

            // アクションボタン
            HStack(spacing: 20) {
                Button("⬅︎ Back") {
                    if !expression.isEmpty {
                        let removed = expression.removeLast()
                        if let idx = numbers.firstIndex(of: Int(String(removed)) ?? -1) {
                            used[idx] = false
                        }
                    }
                }
                .font(.title2)
                .buttonStyle(.bordered)

                Button("Check =") {
                    if isValidExpression(expression) {
                        if let value = evaluateExpression(expression) {
                            if abs(value - 10) < 1e-6 {
                                result = "Correct! 🎉"
                            } else {
                                result = "Result: \(value) (Not 10 😢)"
                                resetNumbers() // 10じゃない場合は初期化
                            }
                        } else {
                            result = "Invalid Expression 🚫"
                            resetNumbers()
                        }
                    } else {
                        result = "式が正しくありません ⚠️"
                        resetNumbers()
                    }
                }

                .disabled(!allNumbersUsed)
                .font(.title2)
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 30)
        }
        .padding()
    }

    // --- 入力処理 ---
    func handleNumber(_ number: Int, index: Int) {
        expression += "\(number)"
        used[index] = true
        lastWasNumber = true
    }

    func handleOperator(_ op: String) {
        guard !expression.isEmpty else {
            if op == "(" { expression += op; lastWasNumber = false }
            return
        }

        let last = expression.last!
        if ["+", "-", "×", "÷"].contains(String(last)) {
            // 連続演算子は置き換え
            expression.removeLast()
        }
        if op == ")" && last == "(" { return } // 空括弧禁止
        expression += op
        lastWasNumber = (op != "(")
    }

    func difficultyLabel() -> String {
        switch difficulty {
        case .easy: return "EASY"
        case .normal: return "NORMAL"
        case .hard: return "HARD"
        }
    }

    // --- バリデーション ---
    func isValidExpression(_ expr: String) -> Bool {
        if expr.isEmpty { return false }

        let chars = Array(expr)
        var balance = 0

        for i in 0..<chars.count {
            let ch = chars[i]
            if ch == "(" {
                balance += 1
                if i > 0, chars[i-1].isNumber || chars[i-1] == ")" { return false }
                if i+1 < chars.count, chars[i+1] == ")" { return false } // 空括弧禁止
            } else if ch == ")" {
                balance -= 1
                if balance < 0 { return false }
                if i > 0, ["+", "-", "×", "÷", "("].contains(String(chars[i-1])) { return false }
            } else if ["+", "-", "×", "÷"].contains(String(ch)) {
                if i == 0 || i == chars.count-1 { return false } // 式の先頭末尾に演算子禁止
                if i > 0, ["+", "-", "×", "÷", "("].contains(String(chars[i-1])) { return false } // 連続演算子禁止
            }
        }

        return balance == 0
    }

    // --- 数式評価 ---
    func evaluateExpression(_ expr: String) -> Double? {
        var formatted = expr
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")

        let pattern = "(?<=^|[^0-9])([0-9]+)(?=$|[^0-9])"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            formatted = regex.stringByReplacingMatches(
                in: formatted,
                options: [],
                range: NSRange(location: 0, length: formatted.count),
                withTemplate: "$1.0"
            )
        }

        let exp = NSExpression(format: formatted)
        if let value = exp.expressionValue(with: nil, context: nil) as? Double {
            return value
        }
        return nil
    }
    
    
    func resetNumbers() {
        expression = ""
        used = [false, false, false, false]
        numbers = [1, 2, 3, 4] // 必要ならランダム化も可能
        lastWasNumber = nil
    }

}
