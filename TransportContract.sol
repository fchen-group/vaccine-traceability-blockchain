pragma solidity ^0.4.24;

import "./Table.sol";

// 购买合约
// 主要功能为疾控中心与生产厂商的疫苗订单协商与数据上链。

contract TransportContract{

	string private vac_log_table_name = "vac_log_table_test";
    string private vac_buy_table_name = "vac_buy_table_test";
    string private producer_table_name = "producer_table_test";
	string private cdc_table_name = "cdc_table";
	string private logistics_table_name = "logistics_table";
	
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
     创建运输计划表
    */
    function createTable() private{
        TableFactory tf = TableFactory(0x1001);

         // 疫苗生产计划表, key : vac_no
        // |     物流企业编号    |      厂商编号     |      订单编号     |     计划路线      |      运输状态       |
        // |-------------------- |-------------------|-------------------|-------------------|-------------------|
        // |     logistics_no    |    producer_no    |     order_no      |      route_plan   |      log_state    |
        // |      string         |      string       |       string      |      string       |       string      |
        // |---------------------|-------------------|-------------------|-------------------|-------------------|
        //
        // 创建表
        tf.createTable(vac_log_table_name, "logistics_no", "producer_no,order_no,route_plan,log_state");
    }
    
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }
    
    //======================================================= 运输订单表 start ========================================================
    /*
     描述 : 查询物流企业编号 是否存在
     参数 ： 
            logistics_no 物流企业编号 
     返回值 ：存在返回0，不存在返回1
    */
    function logistics_no_select(string logistics_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(logistics_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(logistics_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
        
        return ret_code;
    }
	
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
	 描述 : 查询订单编号在购买订单表是否存在
     参数 ： 
            producer_no 生产厂商编号
			order_no    订单编号
     返回值 ：存在返回0，不存在或者该批次未批准返回1
    */
    function buy_order_select(string producer_no,string order_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_buy_table_name);
        Condition condition = table.newCondition();
        condition.EQ("buy_no",order_no);
		
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
		
        return ret_code;
    }
	
	/*
	 描述 : 查询订单编号在运输订单表是否存在
     参数 ： 
            logistics_no 物流企业编号
			order_no    订单编号
     返回值 ：存在返回0，不存在或者该批次未批准返回1
    */
    function log_order_select(string logistics_no,string order_no) constant public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_log_table_name);
        Condition condition = table.newCondition();
        condition.EQ("order_no",order_no);
		
        Entries entries = table.select(logistics_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
		
        return ret_code;
    }
 

	
    /*
     描述 : 运输订单表插入数据
     参数 ： 

			logistics_no  物流企业编号
			producer_no   生产厂商编号
			order_no      订单编号
			route_plan    计划路线
			log_state     运输状态
    
     返回值 ： 0    插入数据成功
               -1   插入数据失败
    */
    function order_insert(string logistics_no, string producer_no, string order_no, string route_plan, string log_state) public returns(int){
        int ret_code = 0;
        
		 if(logistics_no_select(logistics_no) == 0 && producer_no_select(producer_no) == 0 && buy_order_select(producer_no,order_no) == 0 && log_order_select(logistics_no,order_no) == 1)
		 {
			Table table = openTable(vac_log_table_name);
			Entry entry = table.newEntry();
			
			entry.set("logistics_no", logistics_no);
			entry.set("producer_no", producer_no);
			entry.set("order_no", order_no);
			entry.set("route_plan", route_plan);
			entry.set("log_state", log_state);
	 
			
			// 插入
			int count = table.insert(logistics_no, entry);
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
     描述 ：运输订单表删除
     参数 ： 
			logistics_no   物流企业编号
            order_no       运输订单编号 
     返回值 ： 0    删除数据成功
               -1   删除数据失败 
    */
    function order_del(string logistics_no, string order_no) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(vac_log_table_name);
        
        Condition condition = table.newCondition();
        condition.EQ("order_no", order_no);
        
        int count = table.remove(logistics_no, condition);
        if(count == 1){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    
    /*
     描述 ：修改订单数据数据
     参数 ： 
   
			logistics_no  物流企业编号
			producer_no   生产厂商编号
			order_no      订单编号
			route_plan    计划路线
			log_state     运输状态
			
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function order_change(string logistics_no, string producer_no, string order_no, string route_plan, string log_state) public returns(int){
        int ret_code = 0;
        
		TableFactory tf = TableFactory(0x1001);
		Table table = tf.openTable(vac_log_table_name);
		
		Entry entry = table.newEntry();
		entry.set("producer_no", producer_no);
		entry.set("", order_no);
		entry.set("route_plan", route_plan);
		entry.set("log_state", log_state);
		
		Condition condition = table.newCondition();
		condition.EQ("order_no",order_no);
		
		int count = table.update(logistics_no, entry, condition);
		if(count == 1){
			ret_code = 0;
		}
		else{
			ret_code = -1;
		}
    
        return ret_code;
    }
	
	 /*
     描述 ：物流企业修改运输状态
     参数 ： 
   
			logistics_no  物流企业编号
			producer_no   生产厂商编号
			order_no      订单编号
			route_plan    计划路线
			log_state     运输状态
			
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function order_change(string logistics_no, string order_no, string log_state) public returns(int){
        int ret_code = 0;
        
		TableFactory tf = TableFactory(0x1001);
		Table table = tf.openTable(vac_log_table_name);
		
		Entry entry = table.newEntry();
		entry.set("log_state", log_state);
		
		Condition condition = table.newCondition();
		condition.EQ("order_no",order_no);
		
		int count = table.update(logistics_no, entry, condition);
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
           logistics_no   运输企业 
     返回值 ： 
       
            
    */
    function order_select(string logistics_no) constant public returns( bytes32[], bytes32[], bytes32[], bytes32[]){
        Table table = openTable(vac_log_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(logistics_no, condition);
        
        bytes32[] memory producer_no = new bytes32[](uint256(entries.size()));
        bytes32[] memory order_no = new bytes32[](uint256(entries.size()));
        bytes32[] memory route_plan = new bytes32[](uint256(entries.size()));
        bytes32[] memory log_state = new bytes32[](uint256(entries.size()));
		
        for(int i=0; i<entries.size(); i++){
            producer_no[uint256(i)] = entries.get(i).getBytes32("vac_batch");
            order_no[uint256(i)] = entries.get(i).getBytes32("vac_amount");
            route_plan[uint256(i)] = entries.get(i).getBytes32("cdc_no");
			log_state[uint256(i)] = entries.get(i).getBytes32("cdc_no");
        }
        
        return (producer_no, order_no, route_plan, log_state);
    }
    
}


