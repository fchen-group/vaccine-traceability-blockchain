pragma solidity ^0.4.24;

import "./Table.sol";

/**
 * 监管合约, 主要负责：
 * 1. 生成生产厂商表、疾控中心表、接种单位表、冷链物流表
 */

contract InoTContract{
    
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
        
       // tf.createTable(producer_table_name, "producer_no", "producer_name,producer_addr");
        
        // 疾控中心表, key : cdc_no, 由监管机构录入信息 
        // |   疾控中心编号      |   疾控中心名称    |     疾控中心地址  |   疾控中心级别    | 疾控中心收货地址  |
        // |-------------------- |-------------------|-------------------|-------------------|-------------------|
        // |      cdc_no         |      cdc_name     |       cdc_addr    |      cdc_level    | cdc_receive_addr  |  
        // |      String         |       String      |      address      |     int[0,1,2]    |       String      |  
        // |---------------------|-------------------|-------------------|-------------------|-------------------|
        
       // tf.createTable(cdc_table_name, "cdc_no", "cdc_name,cdc_addr,cdc_level,cdc_receive_addr");
        
        // 接种单位表, key : inoculation_no, 由监管机构录入信息 
        // |   接种单位编号      |   接种单位名称    |     接种单位地址  | 接种单位收货地址          |
        // |-------------------- |-------------------|-------------------|---------------------------|
        // |   inoculation_no    |  inoculation_name |  inoculation_addr |inoculation_receive_addr   |  
        // |      String         |       String      |      address      |        String             |  
        // |---------------------|-------------------|-------------------|---------------------------|
        
        tf.createTable(inoculation_table_name, "inoculation_no", "inoculation_name,inoculation_addr,inoculation_receive_addr");
        
        // 冷链物流表, key : logistics_no, 由监管机构录入信息 
        // |   冷链物流编号      |   冷链物流名称    |     冷链物流地址  |
        // |-------------------- |-------------------|-------------------|
        // |    logistics_no     |  logistics_name   |  logistics_addr   |
        // |      String         |       String      |      address      |
        // |---------------------|-------------------|-------------------|
        
        //tf.createTable(logistics_table_name, "logistics_no", "logistics_name,logistics_addr");
    }
    
    // 根据表名打开表   
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }

    
    //======================================================= 接种单位表 start ========================================================
    
    /*
     描述 : 查询接种单位编号是否已存在 
     参数 ： 
            inoculation_no 编号 
     返回值 ： 0    不存在 
               -1   已存在  
    */
    function inoculation_no_select(string inoculation_no) public returns(int){
        int ret_code = 0;
        
        Table table = openTable(inoculation_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(inoculation_no, condition);
        
        if(entries.size() == 0){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    
    /*
     描述 : 接种单位表插入数据
     参数 ： 
            cdc_no          接种单位编号  
            addr            接种单位账户地址  
            name            接种单位名称
            receive_addr    接种单位收货地址 
     返回值 ： 0    插入数据成功
               -1   插入数据失败
               -2   接种单位编号已存在   
    */
    function inoculation_insert(string inoculation_no, address addr, string name, string receive_addr) public returns(int){
        int ret_code = 0;
        
        // 如果接种单位编号不存在
        if(inoculation_no_select(inoculation_no) == 0){
            inoculation_num++;
            
            Table table = openTable(inoculation_table_name);
            Entry entry = table.newEntry();
            
            entry.set("inoculation_no", inoculation_no);
            entry.set("inoculation_name", name);
            entry.set("inoculation_addr", int(addr));
            entry.set("inoculation_receive_addr", receive_addr);
            
            // 插入
            int count = table.insert(inoculation_no, entry);
            if(count == 1){
                ret_code = 0;   // 成功 
            }
            else{
                ret_code = -1;  // 失败? 无权限或者其他错误
                inoculation_num--;
            }
        }
        else{   // 如果接种单位编号存在
            ret_code = -2;
        }
        
        return ret_code;
    }
    
    /*
     描述 ：接种单位表删除数据
     参数 ： 
            no      接种单位编号   
     返回值 ： 0    删除数据成功
               -1   删除数据失败 
    */
    function inoculation_del(string no) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(inoculation_table_name);
        
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
     描述 ：接种单位表修改数据
     参数 ： 
            no      接种单位编号   
            addr    接种单位账户地址 
            name    接种单位名称  
            receive_addr    接种单位收货地址 
     返回值 ： 0    修改数据成功
               -1   修改数据失败 
    */
    function inoculation_change(string no, address addr, string name, string receive_addr) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(inoculation_table_name);
        
        Entry entry = table.newEntry();
        entry.set("inoculation_addr", int(addr));
        entry.set("inoculation_name", name);
        entry.set("inoculation_receive_addr", receive_addr);
        
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
     描述 ：接种单位表查找数据
     参数 ： 
            no      接种单位编号 
     返回值 ： 
            ret_code:
                0:  查询成功
                -1：查询失败 
            addr            接种单位账户地址 
            name            接种单位名称
            recreceive_addr 接种单位收货地址 
    */
    function inoculation_select(string no) public returns(int ret_code, address addr, string name, string receive_addr){
        Table table = openTable(inoculation_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(no, condition);
        
        if(entries.size() == 0){
            ret_code = -1;
            addr = 0;
            name = "";
            receive_addr = "";
        }
        else{
            Entry entry = entries.get(0);
            addr = address(entry.getInt("inoculation_addr"));
            name = byte32ToString(entry.getBytes32("inoculation_name"));
            receive_addr = byte32ToString(entry.getBytes32("inoculation_receive_addr"));
        }
    }
    
    //======================================================= 接种单位表 end ========================================================
    
}