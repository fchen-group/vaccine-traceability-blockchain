pragma solidity ^0.4.24;

import "./Table.sol";

/**
 * 物流企业表
 */

contract LogTContract{
    
    uint private producer_num = 0;  // 生产厂商数量
    uint private cdc_num = 0;   // 疾控中心数量 
    uint private inoculation_num = 0;  // 接种单位数量
    uint private logistics_num = 0; // 冷链物流数量
    
    string private producer_table_name = "producer_table_test";
    string private cdc_table_name = "cdc_table";
    string private inoculation_table_name = "inoculation_table";
    string private logistics_table_name = "logistics_table";
    
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
        
        // 生产厂商表, key : producer_no, 由监管机构录入信息 
        // |   生产厂商编号      |     厂商名称      |     厂商地址      |
        // |-------------------- |-------------------|-------------------|
        // |     producer_no     |    producer_name  |    producer_addr  |  
        // |      String         |       String      |      address      |  
        // |---------------------|-------------------|-------------------|
        
        //tf.createTable(producer_table_name, "producer_no", "producer_name,producer_addr");
        
        // 疾控中心表, key : cdc_no, 由监管机构录入信息 
        // |   疾控中心编号      |   疾控中心名称    |     疾控中心地址  |   疾控中心级别    | 疾控中心收货地址  |
        // |-------------------- |-------------------|-------------------|-------------------|-------------------|
        // |      cdc_no         |      cdc_name     |       cdc_addr    |      cdc_level    | cdc_receive_addr  |  
        // |      String         |       String      |      address      |     int[0,1,2]    |       String      |  
        // |---------------------|-------------------|-------------------|-------------------|-------------------|
        
        //tf.createTable(cdc_table_name, "cdc_no", "cdc_name,cdc_addr,cdc_level,cdc_receive_addr");
        
        // 接种单位表, key : inoculation_no, 由监管机构录入信息 
        // |   接种单位编号      |   接种单位名称    |     接种单位地址  | 接种单位收货地址          |
        // |-------------------- |-------------------|-------------------|---------------------------|
        // |   inoculation_no    |  inoculation_name |  inoculation_addr |inoculation_receive_addr   |  
        // |      String         |       String      |      address      |        String             |  
        // |---------------------|-------------------|-------------------|---------------------------|
        
        //tf.createTable(inoculation_table_name, "inoculation_no", "inoculation_name,inoculation_addr,inoculation_receive_addr");
        
        // 冷链物流表, key : logistics_no, 由监管机构录入信息 
        // |   冷链物流编号      |   冷链物流名称    |     冷链物流地址  |
        // |-------------------- |-------------------|-------------------|
        // |    logistics_no     |  logistics_name   |  logistics_addr   |
        // |      String         |       String      |      address      |
        // |---------------------|-------------------|-------------------|
        
        tf.createTable(logistics_table_name, "logistics_no", "logistics_name,logistics_addr");
    }
    
    // 根据表名打开表   
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }
    
    
    /*
     描述 : 查询冷链物流编号是否已存在 
     参数 ： 
            logistics_no 编号 
     返回值 ： 0    不存在 
               -1   已存在  
    */
    function logistics_no_select(string logistics_no) public returns(int){
        int ret_code = 0;
        
        Table table = openTable(logistics_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(logistics_no, condition);
        
        if(entries.size() == 0){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    
    /*
     描述 : 冷链物流表插入数据
     参数 ： 
            addr    冷链物流账户地址  
            name    冷链物流名称  
     返回值 ： 0    插入数据成功
               -1   插入数据失败
               -2   冷链物流编号已存在   
    */
    function logistics_insert(string logistics_no, address addr, string name) public returns(int){
        int ret_code = 0;
        
        // 如果冷链物流编号不存在
        if(logistics_no_select(logistics_no) == 0){
            logistics_num++;
            
            Table table = openTable(logistics_table_name);
            Entry entry = table.newEntry();
            
            entry.set("logistics_no", logistics_no);
            entry.set("logistics_name", name);
            entry.set("logistics_addr", int(addr));
            // 插入
            int count = table.insert(logistics_no, entry);
            if(count == 1){
                ret_code = 0;   // 成功 
            }
            else{
                ret_code = -1;  // 失败? 无权限或者其他错误
                logistics_num--;
            }
        }
        else{   // 如果冷链物流编号存在
            ret_code = -2;
        }
        
        return ret_code;
    }
    
    /*
     描述 ：冷链物流表删除数据
     参数 ： 
            no      冷链物流编号   
     返回值 ： 0    删除数据成功
               -1   删除数据失败 
    */
    function logistics_del(string no) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(logistics_table_name);
        
        Condition condition = table.newCondition();
        int count = table.remove(no, condition);
        if(count == 1){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    
    /*
     描述 ：冷链物流表修改数据
     参数 ： 
            no          冷链物流编号   
            addr        冷链物流账户地址 
            name        冷链物流名称  
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function logistics_change(string no, address addr, string name) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(logistics_table_name);
        
        Entry entry = table.newEntry();
        entry.set("logistics_addr", int(addr));
        entry.set("logistics_name", name);
        
        Condition condition = table.newCondition();
        
        int count = table.update(no, entry, condition);
        if(count == 1){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    /*
     描述 ：冷链物流表查找数据
     参数 ： 
            no      冷链物流编号 
     返回值 ： 
            ret_code:
                0:  查询成功
                -1：查询失败 
            addr     冷链物流账户地址 
            name     冷链物流名称  
    */
    function logistics_select(string no) public returns(int ret_code, address addr, string name){
        Table table = openTable(logistics_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(no, condition);
        
        if(entries.size() == 0){
            ret_code = -1;
            addr = 0;
            name = "";
        }
        else{
            Entry entry = entries.get(0);
            addr = address(entry.getInt("logistics_addr"));
            name = byte32ToString(entry.getBytes32("logistics_name"));
        }
    }

    
}