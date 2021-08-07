//
//  KMeans.swift
//  Gallery
//
//  Created by 任宇宇 on 2021/8/6.
//

import Foundation
import Accelerate
import Darwin


typealias Vector = [Double]

// Vector Calculation
func vecAdd(vec1:Vector, vec2:Vector) -> Vector {
    var addresult = Vector(repeating: 0.0, count: vec1.count)
    vDSP_vaddD(vec1, 1, vec2, 1, &addresult, 1, vDSP_Length(vec1.count))
    return addresult
}

func vecSub(vec1:Vector, vec2:Vector) -> Vector {
    var subresult = Vector(repeating: 0.0, count: vec1.count)
    vDSP_vsubD(vec2, 1, vec1, 1, &subresult, 1, vDSP_Length(vec1.count))
    return subresult
}

func vecScale(vec:Vector, num:Double) -> Vector {
    var n = num
    var vsresult = Vector(repeating: 0.0, count: vec.count)
    vDSP_vsmulD(vec, 1, &n, &vsresult, 1, vDSP_Length(vec.count))
    return vsresult
}

func vecDot(vec1:Vector, vec2:Vector) -> Double {
    var dotresult = 0.0
    vDSP_dotprD(vec1, 1, vec2, 1, &dotresult, vDSP_Length(vec1.count))
    return dotresult
}

func vecDiv(vec1:Vector, vec2:Vector) -> Vector {
    var divresult = Vector(repeating: 0.0, count: vec1.count)
    vDSP_vdivD(vec2, 1, vec1, 1, &divresult, 1, vDSP_Length(vec1.count))
    return divresult
}

// Mean Vector
func meanVector(inputVectors:[Vector]) -> Vector {
    let vecDimension = inputVectors[0].count
    let vecCount = Double(inputVectors.count)
    let sumVec = inputVectors.reduce(Vector(repeating: 0.0, count: vecDimension),{vecAdd(vec1: $0, vec2: $1)})
    let averageVec = sumVec.map({$0/vecCount})
    return averageVec
}

// Mean Normalization
func meanNormalization(inputVectors:[Vector]) -> [Vector] {
    let averageVec = meanVector(inputVectors: inputVectors)
    let outputVectors = inputVectors.map({vecSub(vec1: $0, vec2: averageVec)})
    return outputVectors
}

// Vector Distance
func euclideanDistance(vec1:Vector, vec2:Vector) -> Double {
    let subVec = vecSub(vec1: vec1, vec2: vec2)
    var distance = 0.0
    vDSP_dotprD(subVec, 1, subVec, 1, &distance, vDSP_Length(subVec.count))
    let distanceSquare = abs(distance)
    
    // just return distanceSquare for speed
    return sqrt(distanceSquare) // or return "sqrt(distanceSquare)"
}

func manhattanDistance(vec1:Vector, vec2:Vector) -> Double {
    var distance = 0.0
    for i in 0..<vec1.count {
        let dist = vec1[i] - vec2[i]
        if dist < 0 {
            distance -= dist
        } else {
            distance += dist
        }
    }
    return distance
}
typealias Matrix = Array<[Double]>

// Matrix Calculation
func matAdd(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecAdd(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matSub(mat1:Matrix, mat2:Matrix) -> Matrix {
    var outputMatrix:Matrix = []
    for i in 0..<mat1.count {
        let vec1 = mat1[i]
        let vec2 = mat2[i]
        outputMatrix.append(vecSub(vec1: vec1, vec2: vec2))
    }
    return outputMatrix
}

func matScale(mat:Matrix, num:Double) -> Matrix {
    let outputMatrix = mat.map({vecScale(vec: $0, num: num)})
    return outputMatrix
}

func transpose(inputMatrix: Matrix) -> Matrix {
    let m = inputMatrix[0].count
    let n = inputMatrix.count
    let t = inputMatrix.reduce([], {$0+$1})
    var result = Vector(repeating: 0.0, count: m*n)
    vDSP_mtransD(t, 1, &result, 1, vDSP_Length(m), vDSP_Length(n))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(result[i*n..<i*n+n]))
    }
    return outputMatrix
}

func matMul(mat1:Matrix, mat2:Matrix) -> Matrix {
    if mat1.count != mat2[0].count {
        print("error")
        return []
    }
    let m = mat1[0].count
    let n = mat2.count
    let p = mat1.count
    var mulresult = Vector(repeating: 0.0, count: m*n)
    let mat1t = transpose(inputMatrix: mat1)
    let mat1vec = mat1t.reduce([], {$0+$1})
    let mat2t = transpose(inputMatrix: mat2)
    let mat2vec = mat2t.reduce([], {$0+$1})
    vDSP_mmulD(mat1vec, 1, mat2vec, 1, &mulresult, 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(p))
    var outputMatrix:Matrix = []
    for i in 0..<m {
        outputMatrix.append(Array(mulresult[i*n..<i*n+n]))
    }
    return transpose(inputMatrix: outputMatrix)
}


// Covariance Matrix
func covarianceMatrix(inputMatrix:Matrix) -> Matrix {
    let t = transpose(inputMatrix: inputMatrix)
    return matMul(mat1: inputMatrix, mat2: t)
}

func svd(inputMatrix:Matrix) -> (u:Matrix, s:Matrix, v:Matrix) {
    let m = inputMatrix[0].count
    let n = inputMatrix.count
    let x = inputMatrix.reduce([], {$0+$1})
    var JOBZ = Int8(UnicodeScalar("A").value)
    var JOBU = Int8(UnicodeScalar("A").value)
    var JOBVT = Int8(UnicodeScalar("A").value)
    var M = __CLPK_integer(m)
    var N = __CLPK_integer(n)
    var A = x
    var LDA = __CLPK_integer(m)
    var S = [__CLPK_doublereal](repeating: 0.0, count: min(m,n))
    var U = [__CLPK_doublereal](repeating: 0.0, count: m*m)
    var LDU = __CLPK_integer(m)
    var VT = [__CLPK_doublereal](repeating: 0.0, count: n*n)
    var LDVT = __CLPK_integer(n)
    let lwork = min(m,n)*(6+4*min(m,n))+max(m,n)
    var WORK = [__CLPK_doublereal](repeating: 0.0, count: lwork)
    var LWORK = __CLPK_integer(lwork)
    var IWORK = [__CLPK_integer](repeating: 0, count: 8*min(m,n))
    var INFO = __CLPK_integer(0)
    if m >= n {
        dgesdd_(&JOBZ, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
    } else {
        dgesvd_(&JOBU, &JOBVT, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &INFO)
    }
    var s = [Double](repeating: 0.0, count: m*n)
    for ni in 0...(min(m,n)-1) {
        s[ni*m+ni] = S[ni]
    }
    var v = [Double](repeating: 0.0, count: n*n)
    vDSP_mtransD(VT, 1, &v, 1, vDSP_Length(n), vDSP_Length(n))
    
    var outputU:Matrix = []
    var outputS:Matrix = []
    var outputV:Matrix = []
    for i in 0..<m {
        outputU.append(Array(U[i*m..<i*m+m]))
    }
    for i in 0..<n {
        outputS.append(Array(s[i*m..<i*m+m]))
    }
    for i in 0..<n {
        outputV.append(Array(v[i*n..<i*n+n]))
    }
    
    return (outputU, outputS, outputV)
}


enum KMeansError: Error {
    case noDimension
    case noClusteringNumber
    case noVectors
    case clusteringNumberLargerThanVectorsNumber
    case otherReason(String)
}

class KMeans {
    
    static let sharedInstance = KMeans()
    init() {}
    
    //MARK: Parameter
    
    //dimension of every vector
    var dimension:Int = 2
    //clustering number K
    var clusteringNumber:Int = 2
    //max interation
    var maxIteration = 100
    //convergence error
    var convergenceError = 0.01
    //number of excution
    var numberOfExcution = 1
    //vectors
    var vectors = Matrix()
    //final centroids
    var finalCentroids = Matrix()
    //final clusters
    var finalClusters = Array<[Int]>()
    //temp centroids
    fileprivate var centroids = Matrix()
    //temp clusters
    fileprivate var clusters = Array<[Int]>()
    
    //MARK: Public
    
    //check parameters
    func checkAllParameters() -> Bool {
        if dimension < 1 { return false }
        if clusteringNumber < 1 { return false }
        if maxIteration < 1 { return false }
        if numberOfExcution < 1 { return false }
        if vectors.count < clusteringNumber { return false }
        return true
    }
    
    //add vectors
    func addVector(_ newVector:Vector) {
        vectors.append(newVector)
    }
    
    func addVectors(_ newVectors:Matrix) {
        for newVector:Vector in newVectors {
            addVector(newVector)
        }
    }
    
    //clustering
    func clustering(_ numberOfExcutions:Int) {
        beginClusteringWithNumberOfExcution(numberOfExcutions)
    }
    
    func reset() {
        vectors.removeAll()
        centroids.removeAll()
        clusters.removeAll()
        finalCentroids.removeAll()
        finalClusters.removeAll()
    }
    
    //MARK: Private
    
    // 1: pick initial clustering centroids randomly
    fileprivate func pickingInitialCentroidsRandomly() {
        let indexes = vectors.count.indexRandom[0..<clusteringNumber]
        var initialCenters = Matrix()
        for index:Int in indexes {
            initialCenters.append(vectors[index])
        }
        centroids = initialCenters
    }
    
    // 2: assign each vector to the group that has the closest centroid.
    fileprivate func assignVectorsToTheGroup() {
        clusters.removeAll()
        for _ in 0..<clusteringNumber {
            clusters.append([])
        }
        for idx in 0..<vectors.count{
            var tempDistance = -1.0
            var groupNumber = 0
            for index in 0..<clusteringNumber {
                if tempDistance == -1.0 {
                    tempDistance = euclideanDistance(vec1: vectors[idx], vec2: centroids[index])
                    groupNumber = index
                    continue
                }
                if euclideanDistance(vec1: vectors[idx], vec2: centroids[index]) < tempDistance {
                    groupNumber = index
                }
            }
            clusters[groupNumber].append(idx)
        }
    }
    
    // 3: recalculate the positions of the K centroids. (return move distance square)
    fileprivate func recalculateCentroids() -> Double {
        var moveDistanceSquare = 0.0
        for index in 0..<clusteringNumber {
            var newCentroid = Vector(repeating: 0.0, count: dimension)
            var vectorSum = Vector(repeating: 0.0, count: dimension)
            for idx in clusters[index] {
                vectorSum = vecAdd(vec1: vectorSum, vec2: vectors[idx])
            }
            var s = Double(clusters[index].count)
            vDSP_vsdivD(vectorSum, 1, &s, &newCentroid, 1, vDSP_Length(vectorSum.count))
            if moveDistanceSquare < euclideanDistance(vec1: centroids[index], vec2: newCentroid) {
                moveDistanceSquare = euclideanDistance(vec1: centroids[index], vec2: newCentroid)
            }
            centroids[index] = newCentroid
        }
        return moveDistanceSquare
    }
    
    // 4: repeat 2,3 until the new centroids cannot move larger than convergenceError or the iteration is over than maxIteration
    fileprivate func beginClustering() -> Double {
        pickingInitialCentroidsRandomly()
        var iteration = 0
        var moveDistance = 1.0
        while iteration < maxIteration && moveDistance > convergenceError {
            iteration += 1
            assignVectorsToTheGroup()
            moveDistance = recalculateCentroids()
        }
        return costFunction()
    }
    
    // the cost function
    fileprivate func costFunction() -> Double {
        var cost = 0.0
        for index in 0..<clusteringNumber {
            for idx in clusters[index] {
                cost += euclideanDistance(vec1: vectors[idx], vec2: centroids[index])
            }
        }
        return cost
    }
    
    // 5: excute again (up to the number of excution), then choose the best result
    private func beginClusteringWithNumberOfExcution(_ number:Int) {
        var number = number
        if number < 1 { return }
        var cost = -1.0
        while number > 0 {
            let newCost = beginClustering()
            if cost == -1.0 || cost > newCost {
                cost = newCost
                finalCentroids = centroids
                finalClusters = clusters
            }
            number -= 1
        }
    }
    
}

//MARK: Helper
//Extension to pick random number. According to stackoverflow.com/questions/27259332/get-random-elements-from-array-in-swift
private extension Int {
    var random: Int {
        return Int(arc4random_uniform(UInt32(abs(self))))
    }
    var indexRandom: [Int] {
        return  Array(0..<self).shuffle
    }
}

private extension Array {
    var shuffle:[Element] {
        var elements = self
        for index in 0..<elements.count {
            let anotherIndex = Int(arc4random_uniform(UInt32(elements.count - index))) + index
            anotherIndex != index ? elements.swapAt(index, anotherIndex) : ()
        }
        return elements
    }
    mutating func shuffled() {
        self = shuffle
    }
}
