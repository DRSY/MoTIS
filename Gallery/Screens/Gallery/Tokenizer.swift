//
//  Tokenizer.swift
//  Gallery
//
//  Created by 任宇宇 on 2021/8/3.
//

import Foundation
import SwiftyJSON
import Regex
import JMUnidecode_Swift
import HTMLEntities


class Tokenizer {
    
    private var byte_encoder: Dictionary<Int, String>! = [:]
    private var byte_decoder: Dictionary<String, Int>! = [:]
    private var encoder: Dictionary<String, Int>! = [:]
    private var decoder: Dictionary<Int, String>! = [:]
    private var cache: Dictionary<String, String> = ["<|startoftext|>": "<|startoftext|>", "<|endoftext|>": "<|endoftext|>"]
    private var bpe_ranks: Dictionary<[String], Int>! = [:]
    private var vocab: Array<String>! = []
    private var merges: [Array<String>] = []
    private var pat: Regex!
    
    private func readLocalFile(forName name: String) -> JSON? {
        do {
            
            if let bundlePath = Bundle.main.path(forResource: name,
                                                 ofType: "json"),
                let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8, allowLossyConversion: false) {
                let json = try JSON(data: jsonData)
                return json
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    func loadJsons() {
        let json_ = readLocalFile(forName: "byte_encoder")
        do {
            let raw_data: [String: String] = try json_?.dictionaryObject as! [String : String]
            for (k, v) in raw_data {
                let kk: Int = Int(k)!
                self.byte_encoder[kk] = v
            }
        } catch {
            print("error")
        }
        let json_1 = readLocalFile(forName: "byte_decoder")
        do {
            let raw_data: [String: Int] = try json_1?.dictionaryObject as! [String : Int]
            for (k, v) in raw_data {
                self.byte_decoder[k] = v
            }
        } catch {
            print("error")
        }
        let json_2 = readLocalFile(forName: "vocab")
        do {
            self.vocab = try json_2?.arrayObject as! [String]
        } catch {
            print("error")
        }
        let json_3 = readLocalFile(forName: "encoder")
        do {
            let raw_data: [String: Int] = try json_3?.dictionaryObject as! [String : Int]
            for (k, v) in raw_data {
                self.encoder[k] = v
            }
        } catch {
            print("error")
        }
        let json_4 = readLocalFile(forName: "decoder")
        do {
            let raw_data: [String: String] = try json_4?.dictionaryObject as! [String : String]
            for (k, v) in raw_data {
                self.decoder[Int(k)!] = v
            }
        } catch {
            print("error")
        }
        let json_5 = readLocalFile(forName: "merges")
        do {
            self.merges = try json_5?.arrayObject as! [Array<String>]
            var cnt = 0
            for tuple in self.merges {
                self.bpe_ranks[tuple] = cnt
                cnt = cnt + 1
            }
        } catch {
            print("error")
        }
        do {
            self.pat = try Regex(pattern: """
<\\|startoftext\\|>|<\\|endoftext\\|>|'s|'t|'re|'ve|'m|'ll|'d|[\\p{L}]+|[\\p{N}]|[^\\s\\p{L}\\p{N}]+
""", options: [.caseInsensitive])
        }catch {
        }
    }
    
    func get_pairs(word: [String]) -> Set<[String]> {
        var pairs = Set<[String]>()
        var prev_char = word[0]
        for idx in 1..<word.count {
            let cur_char = word[idx]
            let arr = [prev_char, cur_char]
            pairs.insert(arr)
            prev_char = cur_char
        }
        return pairs
    }
    
    func bpe(token: String) -> String? {
        if self.cache.keys.contains(token) {
            return self.cache[token]
        }
        var word: Array = Array<String>()
        for ch in token {
            word.append(String(ch))
        }
        word.popLast()
        let lastidx = token.index(token.startIndex, offsetBy: token.count-1)
        word.append(token[lastidx...lastidx]+"</w>")
        var pairs = get_pairs(word: word)
        if pairs.isEmpty {
            return token+"</w>"
        }
        while true {
            var min_val: Int = 999999
            var bigram: [String] = []
            for pair in pairs {
                var tmp: Int = 999999
                if self.bpe_ranks.keys.contains(pair) {
                    tmp = self.bpe_ranks[pair]!
                }
                if tmp < min_val {
                    min_val = tmp
                    bigram = pair
                }
            }
            if self.bpe_ranks.keys.contains(bigram) == false {
                break
            }
            let first: String = bigram[0]
            let second: String = bigram[1]
            var new_word: [String] = []
            var i: Int = 0
            while i < word.count {
                let j = word[i...].firstIndex(of: first)
                if (j != nil) {
                    new_word = new_word + word[i..<j!]
                    i = j!
                }else {
                    new_word = new_word + word[i...]
                    break
                }
                if word[i] == first && i < word.count-1 && word[i+1] == second {
                    new_word.append(first + second)
                    i = i + 2
                }else {
                    new_word.append(word[i])
                    i = i + 1
                }
            }
            word = new_word
            if word.count == 1 {
                break
            }else {
                pairs = get_pairs(word: word)
            }
        }
        let ret: String = word.joined(separator: " ")
        self.cache[token] = ret
        return ret
    }
    
    func basic_clean(text: String) -> String {
        var ret: String = JMUnidecode.unidecode(text)
        ret = ret.htmlUnescape()
        ret = ret.htmlUnescape()
        return ret
    }
    
    func whitespace_clean(text: String) -> String {
        var ret: String = ""
        do {
            let reg = try Regex(pattern: "\\s+")
            ret = reg.replaceAll(in: text, with: " ")
        } catch { }
        ret = ret.trimmingCharacters(in: .whitespacesAndNewlines)
        return ret
    }
    
    func encode(text: String) -> [Int] {
        var bpe_tokens: [Int] = []
        var new_text = whitespace_clean(text: basic_clean(text: text)).lowercased()
        let matches = self.pat.findAll(in: new_text)
        for match in matches {
            let raw_s = match.matched
            var tmp: [String] = []
            let utf8_s = (raw_s as NSString).utf8String
            for i in 0..<raw_s.count {
                tmp.append(self.byte_encoder[Int(utf8_s![i])]!)
            }
            let new_s = tmp.joined(separator: "")
            var cur_bpe_tokens: [Int] = []
            let subwords = bpe(token: new_s)?.split(separator: " ")
            for i in 0..<subwords!.count {
                let subword: String = String(subwords![i])
                let idx: Int = self.encoder[subword]!
                cur_bpe_tokens.append(idx)
            }
            bpe_tokens = bpe_tokens + cur_bpe_tokens
        }
        return bpe_tokens
    }
    
    func tokenize(text: String) -> [Int] {
        let tokens: [Int] = encode(text: text)
        var ret: [Int] = []
        var sot_token: [Int] = []
        sot_token.append(self.encoder["<|startoftext|>"]!)
        var eot_token: [Int] = []
        eot_token.append(self.encoder["<|endoftext|>"]!)
        ret = sot_token + tokens + eot_token
        return ret
    }
}
