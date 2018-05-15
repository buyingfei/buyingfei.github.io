---
title: golang 实现乐观锁
date: 2018-05-15 14:36:06
tags: golang mysql
categories:
- golang
- 数据库
---
**为什么需要锁（并发控制）？**
在多用户环境中，在同一时间可能会有多个用户更新相同的记录，这会产生冲突。这就是著名的并发性问题。

**典型的冲突**
* 丢失更新：一个事务的更新覆盖了其它事务的更新结果，就是所谓的更新丢失。例如：用户A把值从6改为2，用户B把值从2改为6，则用户A丢失了他的更新。
* 脏读：当一个事务读取其它完成一半事务的记录时，就会发生脏读取。例如：用户A,B看到的值都是6，用户B把值改为2，用户A读到的值仍为6。

为了解决这些并发带来的问题。 我们需要引入并发控制机制。

**并发控制机制**
* 悲观锁：假定会发生并发冲突，屏蔽一切可能违反数据完整性的操作。
* 乐观锁：假设不会发生并发冲突，只在提交操作时检查是否违反数据完整性。 乐观锁不能解决脏读的问题。

乐观锁假设认为数据一般情况下不会造成冲突，所以在数据进行提交更新的时候，才会正式对数据的冲突与否进行检测，如果发现冲突了，则让返回用户错误的信息，让用户决定如何去做。

在对数据库进行处理的时候，乐观锁并不会使用数据库提供的锁机制。一般的实现乐观锁的方式就是记录数据版本。

    数据版本,为数据增加的一个版本标识。当读取数据时，将版本标识的值一同读出，数据每更新一次，
        同时对版本标识进行更新。
    当我们提交更新的时候，判断数据库表对应记录的当前版本信息与第一次取出来的版本标识进行比对，
        如果数据库表当前版本号与第一次取出来的版本标识值相等，
        则予以更新，否则认为是过期数据。
  
  实现数据版本有两种方式，第一种是使用版本号，第二种是使用时间戳。
  
  **使用版本号实现乐观锁**
  
  使用版本号时，可以在数据初始化时指定一个版本号，每次对数据的更新操作都对版本号执行+1操作。并判断当前版本号是不是该数据的最新的版本号。
  ![版本号 乐观锁](/source/leguanlock.png)
  
  ```golang
1.查询出商品信息
select (status,status,version) from t_goods where id=#{id}
2.根据商品信息生成订单
3.修改商品status为2
update t_goods 
set status=2,version=version+1
where id=#{id} and version=#{version};  
  ```
  
  **库表设计**
  ```mysql
CREATE TABLE `goods` (
   `id` int(11) NOT NULL AUTO_INCREMENT,
   `name` varchar(20) DEFAULT NULL COMMENT '名称',
   `status` tinyint(4) DEFAULT '0' COMMENT '0 未下单；1 已下单',
   `cnt` int(11) DEFAULT NULL COMMENT '商品数量',
   `version` int(11) DEFAULT '1' COMMENT '版本号',
   PRIMARY KEY (`id`)
 ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4
```

**golang 代码实现**
```golang
package main
import (
	"database/sql"
	_ "github.com/go-sql-driver/mysql"
	"fmt"
	"strconv"
)

var db, err = sql.Open("mysql", "buyf:123456@tcp(192.168.132.128:3306)/tmpdb?charset=utf8") //第一个参数为驱动名

func checkErr(err error)  {
	if err != nil {
		panic(err)
	}
}

func getGoodsById(id int) (int,int) {
	var cnt,version int
	err  := db.QueryRow("select cnt,version from goods where id = ?", id).Scan(&cnt, &version)
	checkErr(err)
	return cnt,version
}

func printGoodsInfo(id int,cnt int,version int)  {
	// int  to string string()
	// string(int num) 为空
	fmt.Println("商品编号： "+ strconv.Itoa(id) + " 当前库存："+ strconv.Itoa(cnt) + " 当前版本："+ strconv.Itoa(version))
}

func modifyGoodsNum(id int,version int) bool {
	cnt,_ := getGoodsById(id)
	if cnt <= 0 {
		fmt.Println("商品编号： "+ strconv.Itoa(id) + "数量小于1，不能下单")
		return false
	}
	stmt, err := db.Prepare(`update goods set cnt = cnt -1 ,version = version + 1 where id = ? and version = ? `)
	checkErr(err)
	res, err := stmt.Exec(id, version)
	checkErr(err)

	num, err := res.RowsAffected()
	checkErr(err)
	if num <= 0 {
		return false
	}
	return true
}


func main()  {
	checkErr(err)
	var cnt1,version1 = getGoodsById(1)
	printGoodsInfo(1,cnt1,version1)
	var cnt2,version2 = getGoodsById(1)
	printGoodsInfo(1,cnt2,version2)
	
	// 修改需要传入版本号，实际过程中，可以加入事务，进行提交和回滚
	if modifyGoodsNum(1,version1) {
		fmt.Println("乐观锁 操作成功")
	}
	if !modifyGoodsNum(1,version2) {
		fmt.Println("乐观锁 操作失败")
	}
}
```

参考链接：
[深入理解乐观锁与悲观锁](http://www.hollischuang.com/archives/934)
[乐观锁与悲观锁——解决并发问题](http://www.cnblogs.com/0201zcr/p/4782283.html)