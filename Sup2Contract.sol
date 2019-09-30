pragma solidity ^0.4.24;

import "./Table.sol";

//监督合约
// 主要功能为以每批疫苗为单位，保存流通过程存证，且与生产厂商和疾控中心核对。

contract Sup2Contract{

    string private producer_table_name = "producer_table_test";
	string private cdc_table_name = "cdc_table";
	string private inoculation_table_name = "inoculation_table";
	string private trace_code_table_name1 = "trace_code_table1";
	string private trace_code_table_name2 = "trace_code_table2";
	string private vac_buy_table_name = "vac_buy_table_test";
	
    function byte32ToString(bytes32 name) view private returns(string){
        bytes memory newname = new bytes(name.length);
        
        for(uint i=0; i<name.length; i++){
            newname[i] = name[i];
        }
        return string(newname);
    }
    
    constructor() public{
        createTable();  
    }

   
    function createTable() private{
        TableFactory tf = TableFactory(0x1001);
		
		
		/*
		 创建溯源码表I，保存生产厂商提交的溯源码下游数据（对应疾控中心）。
		 疾控中心在收到疫苗入库前进行扫码，并上传溯源码信息，与生产厂商上传的溯源码进行对比，
		 若一致则置状态为1，否则置状态为-1，0为初始状态。
		*/
	

         // 溯源码表I, key : producer_no
        // |     生产厂商编号    |      疫苗批次     |    疾控中心编号   |      溯源码       |      一致状态     |
        // |-------------------- |-------------------|-------------------|-------------------|-------------------|
        // |     producer_no     |      vac_batch    |       cdc_no      |      trace_code   |        state      |
        // |      string         |       string      |       string      |      string       |        int        |
        // |---------------------|-------------------|-------------------|-------------------|-------------------|
        //
        // 创建表
        //tf.createTable(trace_code_table_name1, "producer_no", "vac_batch,cdc_no,trace_code,state");
		
		/*
		 创建溯源码表II，保存疾控中心提交的溯源码下游数据（对应接种单位）。
		 接种单位在收到疫苗入库前进行扫码，并上传溯源码信息，与疾控中心上传的溯源码进行对比，
		 若一致则置状态为1，否则置状态为-1，0为初始状态。
		*/
	

         // 溯源码表II, key : cdc_no
        // |     疾控中心编号    |        厂商编号     |     疫苗批次     |    接种单位编号   |       溯源码      |      一致状态     |
        // |-------------------- |---------------------|------------------|-------------------|-------------------|-------------------|
        // |        cdc_no       |      producer_no    |     vac_batch    |       ino_no      |     trace_code    |       state       |
        // |        string       |        string       |      string      |       string      |       string      |        int        |
        // |---------------------|---------------------|------------------|-------------------|-------------------|-------------------|
        //
        // 创建表
        tf.createTable(trace_code_table_name2, "cdc_no", "producer_no,vac_batch,ino_no,trace_code,state");
    }
    
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }
    
    //======================================================= 条件判断 start ========================================================
    /*
     描述 : 查询生产厂商提交的订单信息是否在购买订单表中存在
     参数 ： 
            producer_no 物流企业编号 
			vac_batch   疫苗批次
			cdc_no      疾控中心编号
     返回值 ：存在返回0，不存在返回1
    */
    function order_check_select(string producer_no, string vac_batch, string cdc_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_buy_table_name);
        Condition condition = table.newCondition();
        condition.EQ("vac_batch",vac_batch);
		condition.EQ("cdc_no",cdc_no);
		
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
        
        return ret_code;
    }
	
	 /*
     描述 : 判断溯源码相不相同
     参数 ： 
            trace_code_submit   提交的溯源码
			trace_code_select   查询的溯源码
     返回值 ：相同返回0，不相同返回1
    */
	
	function trace_code_check(string trace_code_submit,bytes32 trace_code_select) constant public returns(int){
		int ret_code = 0;
		string memory temp = byte32ToString(trace_code_select);
		
		if(bytes(trace_code_submit).length != bytes(temp).length ){
			ret_code = 1;
		}
		
		for (uint i = 0; i < bytes(trace_code_submit).length; i ++) {
        if(bytes(trace_code_submit)[i] != bytes(temp)[i]) {
            ret_code = 1;
        }
    }
		return ret_code;
	}
	
	//======================================================= 溯源码表II start =====================================================
	 /*
     描述 : 溯源码表II插入数据，由生产厂商输入
     参数 ： 
			cdc_no       疾控中心编号
			producer_no  生产厂商编号
			vac_batch    疫苗批次
			ino_no       接种单位编号
			trace_code   溯源码
			state        一致状态
    
     返回值 ： 0    插入数据成功
               -1   插入数据失败
    */
    function trace_tableII_insert(string cdc_no, string producer_no, string vac_batch,string ino_no, string trace_code, int state) public returns(int){
        int ret_code = 0;
        
		 if(order_check_select(producer_no, vac_batch, cdc_no) == 0)
		 {
			Table table = openTable(trace_code_table_name2);
			Entry entry = table.newEntry();
			
			entry.set("cdc_no", cdc_no);
			entry.set("producer_no", producer_no);
			entry.set("vac_batch", vac_batch);
			entry.set("ino_no", ino_no);
			entry.set("trace_code", trace_code);
			entry.set("state", 0);
	 		
			// 插入
			int count = table.insert(cdc_no, entry);
			if(count == 1){
				ret_code = 0;   // 成功 
			}
			else{
				ret_code = -1;  // 失败? 无权限或者其他错误
			}
        }
		else{
			ret_code = -1;
		}
        return ret_code;
    }
	
	/*
     描述 ：溯源码表II删除数据
     参数 ： cdc_no,producer_no,vac_batch,ino_no为主键，确定唯一数据
			cdc_no       疾控中心编号
			producer_no  生产厂商编号
			vac_batch    疫苗批次
			ino_no       接种单位编号
     返回值 ： 0    删除数据成功
               -1   删除数据失败 
    */
    function trace_tableII_del(string cdc_no, string producer_no, string vac_batch, string ino_no) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(trace_code_table_name2);
        
        Condition condition = table.newCondition();
        condition.EQ("producer_no", producer_no);
		condition.EQ("vac_batch", vac_batch);
		condition.EQ("ino_no", ino_no);
        
        int count = table.remove(cdc_no, condition);
        if(count == 1){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
	
	/*
     描述 ：接种单位修改溯源表II状态
     参数 ： 
			cdc_no,producer_no,vac_batch,ino_no为主键，确定唯一数据
			cdc_no       疾控中心编号
			producer_no  生产厂商编号
			vac_batch    疫苗批次
			ino_no		 接种单位编号
			trace_code   溯源码
			
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function trace_tableII_change(string cdc_no, string producer_no, string vac_batch, string ino_no, string trace_code) public returns(int){
        int ret_code = 0;
        int state = 0;
		TableFactory tf = TableFactory(0x1001);
		Table table = tf.openTable(trace_code_table_name2);
		
		Condition condition = table.newCondition();
		condition.EQ("producer_no", producer_no);
		condition.EQ("vac_batch", vac_batch);
		condition.EQ("ino_no", ino_no);
		
		Entries entries = table.select(cdc_no, condition);
		Entry entry = table.newEntry();
		
		//判断溯源码是否一致，一致则置状态为1否则置状态为-1
		if(trace_code_check(trace_code,entries.get(0).getBytes32("trace_code")) == 0){
			entry.set("state",1);
		}
		else{
			entry.set("state",-1);
		}
		
		int count = table.update(cdc_no, entry, condition);
		if(count == 1){
			ret_code = 0;
		}
		else{
			ret_code = -1;
		}
    
        return ret_code;
    }
	
	 /*
     描述 ：溯源表II数据查找
     参数 ： 
			cdc_no        疾控中心编号
            producer_no   生产厂商编号 
		    vac_batch     疫苗批次
     返回值 ： 
			cdc_no[]      疾控中心编号数组
			trace_code[]  溯源码数组
			state[]       一致状态数组      
    */
    function trace_tableII_select(string cdc_no, string producer_no, string vac_batch) constant public returns( bytes32[], bytes32[], int[]){
        Table table = openTable(trace_code_table_name2);
        Condition condition = table.newCondition();
		condition.EQ("producer_no",producer_no);
        condition.EQ("vac_batch",vac_batch);
		
        Entries entries = table.select(cdc_no, condition);
        
        bytes32[] memory ino_no = new bytes32[](uint256(entries.size()));
        bytes32[] memory trace_code = new bytes32[](uint256(entries.size()));
        int[] memory state = new int[](uint256(entries.size()));
 
		
        for(int i=0; i<entries.size(); i++){
            ino_no[uint256(i)] = entries.get(i).getBytes32("ino_noh");
            trace_code[uint256(i)] = entries.get(i).getBytes32("trace_code");
            state[uint256(i)] = entries.get(i).getInt("state");
        }
        
        return (ino_no, trace_code, state);
    }
	//======================================================= 溯源码表II end =======================================================
}

