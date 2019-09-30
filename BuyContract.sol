pragma solidity ^0.4.24;

import "./Table.sol";

// 购买合约
// 主要功能为疾控中心与生产厂商的疫苗订单协商与数据上链。

contract BuyContract{

    string private vac_buy_table_name = "vac_buy_table_test";
    string private producer_table_name = "producer_table_test";
	string private vac_plan_table_name = "vac_plan_table_test";
	string private cdc_table_name = "cdc_table";
	
    function byte32ToString(bytes32 name) view private returns(string){
        bytes memory newname = new bytes(name.length);
        
        for(uint i=0; i<name.length; i++){
            newname[i] = name[i];
        }
        return string(newname);
    }
    
    constructor() public{
        createTable();  // 构造函数中创建vac_buy表  
    }

    /*
     创建疫苗生产计划表 
    */
    function createTable() private{
        TableFactory tf = TableFactory(0x1001);

         // 疫苗生产计划表, key : vac_no
        // |     厂商编号        |     批次编号      |     疫苗数量      |     疾控中心编号    |        状态       |      订单编号     |   
        // |-------------------- |-------------------|-------------------|---------------------|-------------------|-------------------|
        // |     producer_no     |     vac_batch     |      vac_amount   |        cdc_no       |      buy_state    |       buy_no      | 
        // |      String         |       string      |      String       |        String       |        int        |       String      |
        // |---------------------|-------------------|-------------------|---------------------|-------------------|-------------------|
        //
        // 创建表
        tf.createTable(vac_buy_table_name, "producer_no", "vac_batch,vac_amount,cdc_no,buy_state,buy_no");
    }
    
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }
    
    //======================================================= 疫苗购买订单表 start ========================================================
    
    /*
     描述 : 查询生产厂商编号 是否存在
     参数 ： 
            producer_no 编号 
     返回值 ：存在返回0，不存在返回1
    */
    function producer_no_select(string producer_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(producer_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
        
        return ret_code;
    }
	
    /*
	 描述 : 查询疫苗批次编号 是否存在
     参数 ： 
            producer_no 生产厂商编号，vac_batch 疫苗批次编号
     返回值 ：存在返回0，不存在或者该批次未批准返回1
    */
    function batch_select(string producer_no,string vac_batch) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_plan_table_name);
        Condition condition = table.newCondition();
        condition.EQ("vac_batch",vac_batch);
		
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
		else{//检查疫苗批准状态
			Entry entry = entries.get(0);
			int vac_state = entry.getInt("vac_state");
			if(vac_state !=1){
				ret_code = 1;}
        }
        return ret_code;
    }
	
    /*
     描述 : 查询疾控中心编号是否存在 
     参数 ： 
            cdc_no 编号
         
     返回值 ：  
            0 存在
			1 不存在
    */
    function cdc_select(string cdc_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(cdc_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(cdc_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
        
        return ret_code;
    }
	
	/*
     描述 : 查询疾控中心订单申请状态  
     参数 ： 
            producer_no 编号
            vac_batch 批次 
     返回值 ：  
            -2 查不到此批次   
            -1 拒绝
            0  未处理
            1  批准
    */
    function order_state_select(string producer_no, string vac_batch) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_buy_table_name);
        Condition condition = table.newCondition();
     
        condition.EQ("vac_batch", vac_batch);
        
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = -2;
        }
        else{
            Entry entry = entries.get(0);
            ret_code = entry.getInt("buy_state");
        }
        
        return ret_code;
    }
	
    /*
     描述 : 疫苗购买订单表插入数据
     参数 ： 
            producer_no 生产厂商编号 
			vac_batch   疫苗批次编号
			vac_amount  购买数量
			cdc_no      疾控中心编号
			buy_state   订单申请状态
			buy_no      订单编号
    
     返回值 ： 0    插入数据成功
               -1   插入数据失败
    */
    function order_insert(string producer_no, string vac_batch, int vac_amount, string cdc_no, string buy_no) public returns(int){
        int ret_code = 0;
        
		 if(producer_no_select(producer_no) == 0 && batch_select(producer_no,vac_batch) == 0 && cdc_select(cdc_no) ==0)
		 {
			Table table = openTable(vac_buy_table_name);
			Entry entry = table.newEntry();
			
			entry.set("producer_no", producer_no);
			entry.set("vac_batch", vac_batch);
			entry.set("vac_amount", vac_amount);
			entry.set("cdc_no", cdc_no);
			entry.set("buy_state", 0);
			entry.set("buy_no", buy_no);
	 
			
			// 插入
			int count = table.insert(producer_no, entry);
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
     描述 ：订单表删除
     参数 ： 
            producer_no      生产厂商编号 
            vac_batch   生产批次 
     返回值 ： 0    删除数据成功
               -1   删除数据失败 
    */
    function order_del(string producer_no, string vac_batch) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(vac_buy_table_name);
        
        Condition condition = table.newCondition();
        condition.EQ("vac_batch", vac_batch);
        
        int count = table.remove(producer_no, condition);
        if(count == 1){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    
    /*
     描述 ：处理订单
     参数 ： 
   
			producer_no  生产厂商编号
			vac_batch    疫苗批次	
			cdc_no		 疾控中心编号
			deal         处理结果
			buy_no       订单编号
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function order_deal(string producer_no, string vac_batch, string cdc_no, int deal_state,string buy_no) public returns(int){
        int ret_code = 0;
        
     
    	TableFactory tf = TableFactory(0x1001);
    	Table table = tf.openTable(vac_buy_table_name);
    
    	Entry entry = table.newEntry();
    	entry.set("buy_state", deal_state);
	    
    	Condition condition = table.newCondition();
   	 condition.EQ("vac_batch",vac_batch);
    	condition.EQ("cdc_no",cdc_no);
    	condition.EQ("buy_no",buy_no);

   	int count = table.update(producer_no, entry, condition);
   	if(count == 1){
	    ret_code = 0;
    	}
    	else{
	    ret_code = -1;
   	}
    
        
        return ret_code;
    }
    /*
     描述 ：订单查找数据
     参数 ： 
           producer_no   生产厂商编号 
     返回值 ： 
       
            
    */
    function order_select1(string producer_no) constant public returns( bytes32[], int[], bytes32[]){
        Table table = openTable(vac_buy_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(producer_no, condition);
        
        bytes32[] memory vac_batch = new bytes32[](uint256(entries.size()));
        int[] memory vac_amount = new int[](uint256(entries.size()));
        bytes32[] memory cdc_no = new bytes32[](uint256(entries.size()));
      
		
        for(int i=0; i<entries.size(); i++){
            vac_batch[uint256(i)] = entries.get(i).getBytes32("vac_batch");
           vac_amount[uint256(i)] = entries.get(i).getInt("vac_amount");
            cdc_no[uint256(i)] = entries.get(i).getBytes32("cdc_no");
			
        }
        
        return (vac_batch, vac_amount, cdc_no);
    }
	
	function order_select2(string producer_no) constant public returns( int[], bytes32[]){
        Table table = openTable(vac_buy_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(producer_no, condition);
        
        int[] memory state = new int[](uint256(entries.size()));
		bytes32[] memory buy_no = new bytes32[](uint256(entries.size()));
		
        for(int i=0; i<entries.size(); i++){
			state[uint256(i)] = entries.get(i).getInt("buy_state");
            buy_no[uint256(i)] = entries.get(i).getBytes32("buy_no");
        }
        
        return ( state, buy_no);
    }
 
    
}


