# banwctr
 Ban weak client‘s transmission.  Applicable to xiaomi wifi.  
   
 禁止信号弱的客户端联网，防止发生全局性的拥塞。  
 
 使用macfilter和parentalctl的firewall规则进行限制。
 
# Usage
  * 将脚本放入小米路由器可写文件夹( eg: /etc/banwctr.sh )中，并且赋予文件可执行的权限  
  
  * 使用crontab自动化执行(每过30s执行一次)
    ```
    * * * * * sleep 30; /etc/banwctr.sh >/dev/null 2>&1
    ```
# Explain
  用于只支持`iwinfo`、`ash`命令的设备 ( eg: MiWiFi )
