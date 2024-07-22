//
//  ViewController.swift
//  TinkoffCalculator
//
//  Created by Daniil Vilchinskiy on 25.02.2024.
//

import UIKit

enum CalculationError: Error {
    case dividedByZero
}

enum Operation: String {
    case add = "+"
    case substract = "-"
    case multily = "x"
    case divide = "/"
    
    func calculate(_ number1: Double, _ number2: Double) throws -> Double {
        switch self {
        case .add:
            return number1 + number2
        case .substract:
            return number1 - number2
        case .multily:
            return number1 * number2
        case .divide:
            if number2 == 0 {
                throw CalculationError.dividedByZero
            }
            return number1 / number2
        }
    }
}

enum CalculationHistoryItem {
    case number(Double)
    case operation(Operation)
}

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var historyButton: UIButton!
    
    var calculatingHistory : [CalculationHistoryItem] = []
    var calculations: [Calculation] = []
    
    
    let calculationHistoryStorage = CalculationHistoryStorage()
    
    lazy var numberFormatter: NumberFormatter = {
        var numberFormatter = NumberFormatter()
        
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.locale = Locale(identifier: "ru_RU")
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter
    }()
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let textButton = sender.titleLabel?.text else { return }
        
        if textButton == "," && label.text?.contains(",") == true {
            return
        }
        
        if label.text == "0" && textButton != "," {
            label.text = textButton
        } else {
            label.text?.append(textButton)
        }
        
    }
    
    @IBAction func operationbuttonPressed(_ sender: UIButton) {
        guard
            let textButton = sender.titleLabel?.text,
            let buttonOperation = Operation(rawValue: textButton)
        else {
            return
        }
        
        guard
            let textLabel = label.text,
            let textNumber = numberFormatter.number(from: textLabel)?.doubleValue
        else {
            return
        }
        
        calculatingHistory.append(.number(textNumber))
        calculatingHistory.append(.operation(buttonOperation))
        
        resetTextLabel()
    }
    
    @IBAction func clearbuttonPressed() {
        calculatingHistory.removeAll()
        
        resetTextLabel()
        
    }
    
    @IBAction func calculatebuttonPressed() {
        guard
            let textLabel = label.text,
            let textNumber = numberFormatter.number(from: textLabel)?.doubleValue
        else {
            return
        }
        
        calculatingHistory.append(.number(textNumber))
        
        do {
            let result = try calculate()
            
            label.text = numberFormatter.string(from: NSNumber(value: result))
            let newCalculation = Calculation(date: Date(), expression: calculatingHistory, result: result)
            calculations.append(newCalculation)
            calculationHistoryStorage.setHistory(calculation: calculations)
        } catch {
            label.text = "Ошибка"
        }
        
        calculatingHistory.removeAll()
    }
    
    @IBAction func showCalculationsList(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let calculationsVS = sb.instantiateViewController(withIdentifier: "CalculationsListViewController")
        if let vc = calculationsVS as? CalculationsListViewController {
            vc.calculations = calculations
        }

        navigationController?.pushViewController(calculationsVS, animated: true)
    }
    
    
    func calculate() throws -> Double {
        guard case .number(let firstNumber) = calculatingHistory[0] else { return 0 }
        
        var currentResult = firstNumber
        
        for index in stride(from: 1, to: calculatingHistory.count - 1, by: 2) {
            guard 
                case .operation(let operation) = calculatingHistory[index],
                case .number(let number) = calculatingHistory[index + 1]
            else {
                break
            }
            currentResult = try operation.calculate(currentResult, number)
        }
        
        return currentResult
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        resetTextLabel()
        
        historyButton.accessibilityIdentifier = "HistoryButton"
        calculations = calculationHistoryStorage.loadHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func resetTextLabel() {
        label.text = "0"
    }
}

