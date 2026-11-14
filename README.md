# SPS-maker
Making X files （SPS2.0）
# SPSSolution 使用说明
## **1\.用途**
根据 S 文件、R 文件、关系划分表和参数表，生成 **SPS 2\.1 定宽格式** X 关系文件。支持SPS2\.1格式和CSV输入输出。
## **2\.特点**
- 常规观测：按 recvLineStep 逐线推算。
- 加密排列：Fixed Line Min/Max 指定范围，范围内实际线全部参与，忽略间隔。
- 不对称排列：halfApertureSmall/Large 分别设置两侧道数。
- 两种模式可逐 Swath 混用；特殊接收方式需在关系划分文件中约定，工具不自动推断。
## **3\.运行**
- **MATLAB**：R2020b 及以上，SPSSolution 启动。
- **exe**：双击 SPSSolution\.exe，需先装对应版本 MATLAB Runtime；首次启动稍慢。
## **4\.输入**
- **S/R 文件**：支持 **SPS 2\.1 定宽文本**（\.txt/\.sps/\.dat）和 **CSV**（\.csv）两种格式，在已知模板基础上修改。CSV 需含表头 Line、Point，可选 X、Y、Elev；分隔符默认逗号，可在参数表用 csvDelimiter 指定（,、; 或 tab）。格式可在参数表用 sFileFormat/rFileFormat 指定（sps/csv），留空则按扩展名自动判断。
- **关系划分\.xlsx**：工作表 Swath，在已知模板基础上修改，必含 Swath、First/Last Shot、First/Last Shot Line、First/Last Receiver Line；可选 Fixed Line Min/Max（都填走 fixedRange，留空走 interval，只填一列报错）。
- **params\.xlsx**：Parameter/Value 两列，在已知模板基础上修改。常用参数：recvLineStep（默认16）、d（2）、halfApertureSmall/Large（320）、P\_offset（0）、gapHalfWidth/splitOnGap（0/0）、pointCode/chInc（1/1）、outputXFile、sFileFormat/rFileFormat、csvDelimiter。
## **5\.操作**
1. 启动 SPSSolution。
2. 依次选 4 个文件；Excel 选完后下方表格自动加载，可核对。
3. 点“开始生成”，看进度和日志。
4. 完成后在 outputXFile 查看 X 文件（已存在会覆盖，请备份）。
## **6\.模式判定**
- **interval**：Fixed Line Min/Max 留空，按 First Receiver Line 起、recvLineStep 步长推算到 Last Receiver Line。
- **fixedRange**：两列都填，以 R 文件中实际存在、线号在闭区间内的检波线为准，全部参与，忽略 recvLineStep，不受 12 条限制。
单线取道两模式一致：炮点投影为中心，两边各取 halfApertureSmall/Large 道，投影点不取检波点；同线不拆分，换线才生成新 X 记录。
## **7\.输出**
SPS 2\.1 定宽文本，含记录号、炮线号、炮点号、点代码、首末通道号、通道增量、检波线号、首末检波点号、通道增量。记录号按炮递增，通道号跨线连续累加。
## **8\.常见问题**
- 提示选全 4 个文件 → 补全路径。
- 表格加载失败 → 查 Excel 表头、工作表名 Swath。
- 某 Swath 0 条 → 查炮点/炮线范围；fixedRange 查范围与 R 线号有无交集。
- Fixed Line Min/Max 报错 → 两列必须同时填或同时留空。
- 线数/通道号不符 → interval 查 recvLineStep；fixedRange 查 R 线号；不对称查 halfApertureSmall/Large。
- exe 无反应 → 装对应 MATLAB Runtime。
