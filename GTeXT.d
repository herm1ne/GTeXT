//
//  GTeXT.d
//  GTeXT
//
//  Created by thotgamma on 2016/02/04.
//
//	#このファイル:
//		GTeXTの本体ファイル。
//		今の所構造体をPDFに出力するコードだけが実装されている。
//
//	#(今実装されている)コードの流れ:
//		1.PDFを構成するオブジェクトが入った配列からオブジェクトを一つずつ取り出し、ファイルに書き出す。
//		2.この際、書き出した文字のバイト数を数えてsizeに足す。
//		3.すなわちsizeは先頭からその次のオブジェクトまでのバイト数を示す。
//		4.それぞれのオブジェクトまでのバイト数を、sizeをdistanceFromTop[]に格納することでメモる。(詳しくはoutputpdf()のコメント参照のこと)
//		5.最後にdistanceFromTop[]を用いて相互参照テーブルを作成する。
//
//

import std.stdio;
import std.algorithm.iteration;
import std.array;
import std.conv;
import std.file;
import std.string;
import std.regex;
import std.utf;
import std.format;
import std.encoding;

//ディレクトリの要素の構造体
struct pdfRecord{
	string primary, secondary;

	this(string a, string b){
		primary = a;
		secondary = b;
	}
}

struct pdfObject{
	pdfRecord[] records;
	string[] stream;
}

pdfObject[] pdfObjects;
int[] distanceFromTop;
string outputFile;

void main(){

	//PDF書き出し
	parser();
	outputpdf();

}

void parser(){
	//デバッグを素早く行うため入力ファイル名はあらかじめ記入しておいた
	string inputFile = "input.gt";

	//ADD 0 0 obj
	pdfObject obj;
	pdfObjects ~= obj;

	//ADD 1 0 obj(ROOT)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/Catalog");
	obj.records ~= pdfRecord("/Pages","3 0 R");
	pdfObjects ~= obj;

	auto fin = File(inputFile,"r");

	//PDFのメタ情報を格納する変数
	string title;
	string author;

	string line;
	string[] command;

	bool mathMode = false;
	bool subcommandMode = false;

	string subcommand;

	while(!fin.eof){
		line = fin.readln.chomp;	//.chompで改行コードを除去
		if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				//コマンド行
				line = line[2 .. $];
				command = line.split(" ");
				switch(command[0]){
					case "title":
						title = command[1];
						break;
					case "author":
						author = command[1];
						break;
					default:
				}
			}
		}
	}

	//デバッグのため出力
	writeln("title: " ~ title);
	writeln("author: " ~ author);

	if(title == null){
		outputFile = "noname.pdf";
	}else{
		outputFile = title ~ ".pdf";
	}

	//ADD 2 0 obj (INFO)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Title","(" ~ title ~ ")");
	obj.records ~= pdfRecord("/Author","(" ~ author ~ ")");
	obj.records ~= pdfRecord("/Creator", "(GTeXT)");
	pdfObjects ~= obj;

	//ADD 3 0 obj (PAGETREE)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/Pages");
	obj.records ~= pdfRecord("/Kids","[4 0 R]");
	obj.records ~= pdfRecord("/Count", "1");
	pdfObjects ~= obj;

	//ADD 4 0 obj (PAGEOBJECT)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/Page");
	obj.records ~= pdfRecord("/Parent","3 0 R");
	obj.records ~= pdfRecord("/Resources","5 0 R");
	obj.records ~= pdfRecord("/MediaBox","[0 0 595 842]");
	obj.records ~= pdfRecord("/Contents","11 0 R");
	pdfObjects ~= obj;

	//ADD 5 0 obj (Resources)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Font","6 0 R");
	pdfObjects ~= obj;

	//ADD 6 0 obj (Font)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/F0","7 0 R");
	pdfObjects ~= obj;

	//ADD 7 0 obj(F0)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/Font");
	obj.records ~= pdfRecord("/BaseFont","/KozMinPro6N-Regular");
	obj.records ~= pdfRecord("/Subtype","/Type0");
	obj.records ~= pdfRecord("/Encoding","/UniJIS-UTF16-H");
	obj.records ~= pdfRecord("/DescendantFonts","[8 0 R]");
	pdfObjects ~= obj;

	//ADD 8 0 obj(DesendantFonts)
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/Font");
	obj.records ~= pdfRecord("/Subtype","/CIDFontType0");
	obj.records ~= pdfRecord("/BaseFont","/KozMinPr6N-Regular");
	obj.records ~= pdfRecord("/CIDSystemInfo","9 0 R");
	obj.records ~= pdfRecord("/FontDescriptor","10 0 R");
	pdfObjects ~= obj;
	
	//ADD 9 0 obj
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Registry","(Adobe)");
	obj.records ~= pdfRecord("/Ordering","(Japan1)");
	obj.records ~= pdfRecord("/Supplement","6");
	pdfObjects ~= obj;
	
	//ADD 10 0 obj
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Type","/FontDescriptor");
	obj.records ~= pdfRecord("/FontName","/KozMinPro6N-Regular");
	obj.records ~= pdfRecord("/Flags","4");
	obj.records ~= pdfRecord("/FontBBox","[-437 -340 1147 1317]");
	obj.records ~= pdfRecord("/ItalicAngle","0");
	obj.records ~= pdfRecord("/Ascent","1317");
	obj.records ~= pdfRecord("/Descent","-349");
	obj.records ~= pdfRecord("/CapHeight","742");
	obj.records ~= pdfRecord("/StemV","80");
	pdfObjects ~= obj;

	//ファイル読み込みのシーカーを頭に戻す
	fin.rewind();

	//11 obj
	obj.records = null;
	obj.stream = null;
	obj.records ~= pdfRecord("/Length","58");
	obj.stream ~= "1. 0. 0. 1. 50. 720. cm"; 
	obj.stream ~= "BT";
	obj.stream ~= "/F0 36 Tf";
	obj.stream ~= "40 TL";
	obj.stream ~= "<";

	while(!fin.eof){
		line = fin.readln.chomp;
		//コマンド行もしくは空行であればスキップ
		if(line.length == 0){
			//空行はパラグラフ変更である
			continue;
		}else if(line.length >= 2){
			if(line[0 .. 2] == "#!"){
				continue;
			}
		}

		//1文字ずつ処理する
		foreach(str;line){
			if(subcommandMode == true){
				if(match(to!string(str),r"[a-z]|[A-Z]")){
					subcommand ~= str;
				}else{
					write("!subcommand: " ~ subcommand ~ "!");
					subcommand = "";
					subcommandMode = false;

					if(str == '['){
						if(mathMode == true){
							writeln("error! \"[\"in[]");
						}else{
							write("!mathModein!");
							mathMode = true;
						}
					}
				}
			}else{
				switch(str){
					case '[':
						if(mathMode == true){
							writeln("error! \"[\"in[]");
						}else{
							write("!mathModein!");
							mathMode = true;
						}
						break;
					case ']':
						if(mathMode == true){
							mathMode = false;
							write("!mathModeout!");
						}else{
							writeln("error! \"[\"in[]");

						}
						break;
					case '#':
						subcommandMode = true;
						break;
					default:
						write(str);
						auto writer = appender!string();
						wchar buff = to!wchar(str);
						formattedWrite(writer,"%x",buff);
						obj.stream[$-1] ~= writer.data;
				}
			}
		}
		write("\n");
	}
	obj.stream[$-1] ~= "> Tj T*";
	obj.stream ~= "ET";
	pdfObjects ~= obj;


}


void outputpdf(){

	auto fout = File(outputFile,"w");

	//ヘッダ
	fout.writeln("%PDF-1.3");
	fout.write("%");
	fout.rawWrite([0xE2E3CFD3]); //バイナリファイルであることを明示
	fout.write("\n");
	int size = 15; //ヘッダーの分だけ下駄を履かせた

	//オブジェクトの書き出し
	for(uint i = 1; i < pdfObjects.length; i++){

		distanceFromTop ~= size; //ファイル先端から該当オブジェクトまでのバイト数を格納

		fout.writeln(to!string(i) ~ " 0 obj");
		size += to!string(i).length; //n 0 objのnの部分のバイト数を足す
		fout.writeln("<<");
		foreach(element;pdfObjects[i].records){
			fout.writeln(element.primary ~ " " ~ element.secondary);
			size += element.primary.length + element.secondary.length + 2; //(文字列の長さ+スペース+改行)
		}
		fout.writeln(">>");
		if(pdfObjects[i].stream != null){ //ストリームがある場合
			fout.writeln("stream");
			foreach(str;pdfObjects[i].stream){
				fout.writeln(str);
				size += str.length + 1; //(文字列の長さ + 改行)
			}
			fout.writeln("endstream");
			size += 17; //streamとendstreamの分のバイト数を足す
		}
		fout.writeln("endobj");
		size += 20; //0 objとかendobjとかのぶん
	}
	
	//相互参照テーブルの書き出し
	fout.writeln("xref");
	fout.writeln("0 " ~ to!string(pdfObjects.length));
	fout.writeln("0000000000 65535 f ");
	foreach(i;distanceFromTop){
		fout.writeln(rightJustify(to!string(i),10,'0') ~ " 00000 n ");
	}
	fout.writeln("trailer");
	fout.writeln("<<");
	fout.writeln("/Size " ~ to!string(pdfObjects.length));
	fout.writeln("/Root 1 0 R");
	fout.writeln(">>");
	fout.writeln("startxref");
	fout.writeln(to!string(size)); //相互参照テーブルまでのバイト数=全てのオブジェクトのバイト数の和
	fout.writeln("%%eof");

}
