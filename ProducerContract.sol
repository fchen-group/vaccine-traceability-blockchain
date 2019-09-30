pragma solidity ^0.4.24;

import "./Table.sol";

// ������Լ
// ��Ҫ�����¼�������̵������ƻ����������ܻ�����������α��

contract ProducerContract{

    string private vac_plan_table_name = "vac_plan_table_test";
    string private producer_table_name = "producer_table_test";
	
    function byte32ToString(bytes32 name) view private returns(string){
        bytes memory newname = new bytes(name.length);
        
        for(uint i=0; i<name.length; i++){
            newname[i] = name[i];
        }
        return string(newname);
    }
    
    constructor() public{
        createTable();  // ���캯���д���vac_plan��  
    }

    /*
     �������������ƻ��� 
    */
    function createTable() private{
        TableFactory tf = TableFactory(0x1001);

         // ���������ƻ���, key : vac_no
        // |     ���̱��        |     ���α��      |     ��������      |     ��������      |    ��������״̬   |    ԭ����         |    ��Ӧ��         |    ʱ��           |    ��Դ��         |
        // |-------------------- |-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|
        // |     producer_no     |     vac_batch     |      vac_name     |    vac_amount     |     vac_state     |    material       |    provider       |    vac_time       |    source_code    |
        // |      String         |       string      |      String       |        int        |      int{-1,0,1}  |     String        |     String        |     String        |      String       |
        // |---------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|
        //
        // ������
        tf.createTable(vac_plan_table_name, "producer_no", "vac_batch,vac_name,vac_amount,vac_state,material,provider,vac_time,source_code");
    }
    
    function openTable(string table_name) private returns(Table){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(table_name);
        return table;
    }
    
    //======================================================= ���������ƻ��� start ========================================================
     /*
     ���� : ��ѯ�������̱���Ƿ���� 
     ���� �� 
            producer_no ��� 
     ����ֵ �����ڷ���0�������ڷ���1
    */
	function producer_no_select(string producer_no) public returns(int){
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
     ���� : ��ѯ�����������α�� 
     ���� �� 
            producer_no ��� 
     ����ֵ �� �����ڷ���0�������ڷ���1
    */
    function vac_batch_select(string producer_no,string vac_batch) public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_plan_table_name);
        Condition condition = table.newCondition();
		condition.EQ("vac_batch",vac_batch);
        
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = 1;
        }
        
        return ret_code;
    }
    
    /*
     ���� : ��ѯ�����������α������״̬  
     ���� �� 
            producer_no ���
            batch ���� 
     ����ֵ ��  
            -2 �鲻��������   
            -1 �ܾ�
            0  δ����
            1  ��׼
    */
    function vac_state_select(string producer_no, string batch) public returns(int){
        int ret_code = 0;
        
        Table table = openTable(vac_plan_table_name);
        Condition condition = table.newCondition();
     
        condition.EQ("vac_batch", batch);
        
        Entries entries = table.select(producer_no, condition);
        
        if(entries.size() == 0){
            ret_code = -2;
        }
        else{
            Entry entry = entries.get(0);
            ret_code = entry.getInt("vac_state");
        }
        
        return ret_code;
    }
    
    /*
     ���� : ���������ƻ����������
     ���� �� 
            producer_no �������̱�� 
			vac_batch   ���α��
            name        �������� 
            amount      �������� 
            material    ԭ���� 
            provider    ��Ӧ�� 
    
     ����ֵ �� 0    �������ݳɹ�
               -1   ��������ʧ��
    */
    function vac_plan_insert(string producer_no, string vac_batch, string name, int amount, string material, string provider) public returns(int){
        int ret_code = 0;
		//�ж��������̱���Ƿ����  ����  ���α�Ų�δ�ظ�
        if(producer_no_select(producer_no) == 0 && vac_batch_select(producer_no,vac_batch) == 1)
		{
			Table table = openTable(vac_plan_table_name);
			Entry entry = table.newEntry();
			
			entry.set("producer_no", producer_no);
			entry.set("vac_batch", vac_batch);
			entry.set("vac_name", name);
			entry.set("vac_amount", amount);
			entry.set("vac_state", 0);
			entry.set("material", material);
			entry.set("provider", provider);
			entry.set("vac_time", int(now));
			entry.set("source_code", "");
			
			// ����
			int count = table.insert(producer_no, entry);
			if(count == 1){
				ret_code = 0;   // �ɹ� 
			}
			else{
				ret_code = -1;  // ʧ��? ��Ȩ�޻�����������
			}
       }
	   else{
			ret_code = -1;
	   }
        return ret_code;
    }
    
    /*
     ���� �����������ƻ���ɾ������
     ���� �� 
            no      �������̱�� 
            batch   �������� 
     ����ֵ �� 0    ɾ�����ݳɹ�
               -1   ɾ������ʧ�� 
    */
    function vac_plan_del(string no, string batch) public returns(int){
        int ret_code = 0;
        
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable(vac_plan_table_name);
        
        Condition condition = table.newCondition();
        condition.EQ("vac_batch", batch);
        
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
     ���� ����ܻ���������������
     ���� �� 
            no          �������̱��   
            batch       ���� 
			deal        ��������  -1�ܾ� 1��׼
     ����ֵ �� 0    �޸����ݳɹ�
               -1   �޸�����ʧ�� 
    */
    function vac_plan_agree(string no, string batch,int deal) public returns(int){
        int ret_code = 0;
       
		TableFactory tf = TableFactory(0x1001);
		Table table = tf.openTable(vac_plan_table_name);
		
		Condition condition = table.newCondition();
		condition.EQ("vac_batch",batch);
		
		Entry entry = table.newEntry();
		entry.set("vac_state", deal);
		
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
     ���� �����������޸�����
     ���� �� 
            no          �������̱��   
            batch       ���� 
            name        �������� 
            amount      �������� 
            material    ԭ���� 
            provider    ��Ӧ�� 
     ����ֵ �� 0    �޸����ݳɹ�
               -1   �޸�����ʧ�� 
    */
    function vac_plan_change(string no, string batch, string name, int amount, string material, string provider) public returns(int){
        int ret_code = 0;
        
        if(vac_state_select(no, batch) == 0){
            TableFactory tf = TableFactory(0x1001);
            Table table = tf.openTable(vac_plan_table_name);
            
            Entry entry = table.newEntry();
            entry.set("vac_name", name);
            entry.set("vac_amount", amount);
            entry.set("material", material);
            entry.set("provider", provider);
            entry.set("vac_time", int(now));
            
            Condition condition = table.newCondition();
            
            int count = table.update(no, entry, condition);
            if(count == 1){
                ret_code = 0;
            }
            else{
                ret_code = -1;
            }
        }
        else{
            ret_code = -1;
        }
        
        return ret_code;
    }
    /*
     ���� ������ƻ����������
     ���� �� 
            no      �������̱�� 
     ����ֵ �� 
       
            
    */
    function vac_plan_select1(string no) public returns(bytes32[], bytes32[], int[], bytes32[]){
        Table table = openTable(vac_plan_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(no, condition);
        
        bytes32[] memory batch = new bytes32[](uint256(entries.size()));
        bytes32[] memory name = new bytes32[](uint256(entries.size()));
        int[] memory amount = new int[](uint256(entries.size()));
        bytes32[] memory material = new bytes32[](uint256(entries.size()));
        
        for(int i=0; i<entries.size(); i++){
            batch[uint256(i)] = entries.get(i).getBytes32("vac_batch");
            name[uint256(i)] = entries.get(i).getBytes32("vac_name");
            amount[uint256(i)] = entries.get(i).getInt("vac_amount");
            material[uint256(i)] = entries.get(i).getBytes32("material");
        }
        
        return (batch, name, amount, material);
    }
    
    function vac_plan_select2(string no) public returns(bytes32[], int[], int[], bytes32[]){
        Table table = openTable(vac_plan_table_name);
        Condition condition = table.newCondition();
        
        Entries entries = table.select(no, condition);
        
        bytes32[] memory provider = new bytes32[](uint256(entries.size()));
        int[] memory time = new int[](uint256(entries.size()));
        int[] memory state = new int[](uint256(entries.size()));
        bytes32[] memory code = new bytes32[](uint256(entries.size()));
        
        for(int i=0; i<entries.size(); i++){
            provider[uint256(i)] = entries.get(i).getBytes32("provider");
            time[uint256(i)] = entries.get(i).getInt("vac_time");
            state[uint256(i)] = entries.get(i).getInt("vac_state");
            code[uint256(i)] = entries.get(i).getBytes32("source_code");
        }
        
        return (provider, time, state, code);
    }
    
}


