//
//  BMICalculatorView.swift
//  AlipayDemo
//
//  Created by Hanlun Wang on 2/7/25.
//

import SwiftUI

// Add these models after the imports
struct BMIResponse: Codable {
    let reason: String
    let result: BMIResult
    let error_code: Int
}

struct BMIResult: Codable {
    let idealWeight: Float
    let normalWeight: String
    let level: Int
    let levelMsg: String
    let danger: String
    let bmi: Float
    let normalBMI: String
}

class BMICalculatorViewModel : ObservableObject {
    // 性别,1:男 2:女, 默认1
    @Published var sex : Int = 1
    // 计算标准, 1:中国 2:亚洲 3:国际, 默认1
    @Published var role : Int = 1
    // 身高(CM), 支持最多1位小数; 如: 178
    
    @Published var heightInt: Int = 170
    @Published var heightDecimal: Int = 0
    @Published var weightInt: Int = 60
    @Published var weightDecimal: Int = 0
    
    var height: String {
        get { "\(heightInt).\(heightDecimal)" }
        set { }
    }
    // 体重(KG), 支持最多1位小数; 如: 67.8
    var weight: String {
        get { "\(weightInt).\(weightDecimal)" }
        set { }
    }
    
    // results
    // 标准体重
    @Published var idealWeight : Float = 0
    // 正常体重范围
    @Published var normalWeight : Float = 0
    // 等级, 0偏瘦 1正常 2偏胖 3肥胖 4重度肥胖 5极重度肥胖
    @Published var level : Int = 0
    // 等级描述
    @Published var levelMsg : String = ""
    // 相关疾病发病危险
    @Published var danger : String = ""
    // BMI指数
    @Published var bmi : Float = 10.0
    // BMI指数范围
    @Published var normalBMI : String = "aaa"
    
    @Published var showResult : Bool = false
    
    @Published var isLoading: Bool = false
    
    func calculateBMI() {
        isLoading = true
        let baseURL = "https://apis.juhe.cn/fapig/calculator/weight"
        let apiKey = "65415521cbcdf6bb82a2e9400f0abb7b"
        
        guard var components = URLComponents(string: baseURL) else { return }
        
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "sex", value: String(sex)),
            URLQueryItem(name: "role", value: String(role)),
            URLQueryItem(name: "height", value: height),
            URLQueryItem(name: "weight", value: weight)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(BMIResponse.self, from: data)
                    self?.updateResults(with: response.result)
                    self?.showResult = true
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
    
    private func updateResults(with result: BMIResult) {
        self.idealWeight = result.idealWeight
        self.normalWeight = Float(result.normalWeight.components(separatedBy: " ~ ").first ?? "0") ?? 0
        self.level = result.level
        self.levelMsg = result.levelMsg
        self.danger = result.danger
        self.bmi = result.bmi
        self.normalBMI = result.normalBMI
    }
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("计算中...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.9))
    }
}

struct BMIResultView: View {
    @EnvironmentObject var vm: BMICalculatorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // BMI Value Display
                VStack(spacing: 8) {
                    Text("您的BMI指数")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f", vm.bmi))
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                // Level Indicator
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(getLevelColor(vm.level))
                    Text(vm.levelMsg)
                        .font(.title3)
                        .bold()
                }
                .padding(.vertical, 5)
                
                // Detailed Results
                VStack(spacing: 20) {
                    ResultRow(title: "标准BMI范围", value: vm.normalBMI)
                    ResultRow(title: "标准体重", value: "\(String(format: "%.1f", vm.idealWeight)) kg")
                    ResultRow(title: "健康风险", value: vm.danger)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("返回")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GrowingButton())
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("BMI结果")
        }
    }
    
    private func getLevelColor(_ level: Int) -> Color {
        switch level {
        case 0: return .blue    // 偏瘦
        case 1: return .green   // 正常
        case 2: return .yellow  // 偏胖
        case 3: return .orange  // 肥胖
        default: return .red    // 重度肥胖
        }
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct BMICalculatorView: View {
    @StateObject var vm : BMICalculatorViewModel = .init()
    
    var body: some View {
        ZStack {
            // Existing main content
            VStack(alignment:.center, spacing: 20) {
                Text("BMI计算器")
                    .font(.title)
                    .padding()
                
                VStack {
                    Text("性别")
                        .font(.headline)
                    Picker("性别选择", selection: $vm.sex) {
                        Text("男").tag(1)
                        Text("女").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
                
                VStack {
                    Text("计算标准")
                        .font(.headline)
                    Picker("计算标准选择", selection: $vm.role) {
                        Text("中国").tag(1)
                        Text("亚洲").tag(2)
                        Text("国际").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .center, spacing: 20) {
                    Text("身高（CM）")
                        .font(.headline)
                    HStack(spacing: 0) {
                        Picker("", selection: $vm.heightInt) {
                            ForEach(100...250, id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text(".")
                            .font(.title2)
                            .padding(.horizontal, 4)
                        
                        Picker("", selection: $vm.heightDecimal) {
                            ForEach(0...9, id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()
                    }
                    .frame(height: 120)
                    
                    Text("体重（KG）")
                        .font(.headline)
                    HStack(spacing: 0) {
                        Picker("", selection: $vm.weightInt) {
                            ForEach(30...200, id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                        
                        Text(".")
                            .font(.title2)
                            .padding(.horizontal, 4)
                        
                        Picker("", selection: $vm.weightDecimal) {
                            ForEach(0...9, id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()
                    }
                    .frame(height: 120)
                }
                .padding(.vertical)
                
                Button {
                    vm.calculateBMI()
                } label: {
                    Text("计算BMI")
                }
                .buttonStyle(GrowingButton())

                
                Spacer()
            }
            .padding(.horizontal, 40)
            .background(Color.gray.opacity(0.1))
            .sheet(isPresented: $vm.showResult) {
                BMIResultView()
                    .environmentObject(vm)
            }
            
            // Loading overlay
            if vm.isLoading {
                LoadingView()
            }
        }
    }
}

#Preview {
    BMICalculatorView()
}
