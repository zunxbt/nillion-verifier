<h2 align=center> Nillion Verifier One Click Guide </h2>

## Prerequisites
- Need to have a VPS with the following requirements

 | Resource          | Requirement   |
|-------------------|---------------|
| RAM               | 4 GB          |
| CPU Cores         | 2 cores       |
| Storage           | 50 GB SSD     |
| Internet Speed    | 200 Mbps      |

- If you don't know how to buy or where to buy VPS, you can watch this [youtube video](https://youtu.be/vNBlRMnHggA?t=293)
- PQ Hosting website link : [Click Here](https://pq.hosting/?from=622403&lang=en)

## Installations
- You can use either this command

```bash
[ -f "nillion.sh" ] && rm nillion.sh; wget -q -O nillion.sh https://raw.githubusercontent.com/zunxbt/nillion-verifier/refs/heads/main/nillion.sh && chmod +x nillion.sh && ./nillion.sh
```
- Or this command
```bash
[ -f "nillion.sh" ] && rm nillion.sh; curl -sSL -o nillion.sh https://raw.githubusercontent.com/zunxbt/nillion-verifier/refs/heads/main/nillion.sh && chmod +x nillion.sh && ./nillion.sh
```

## Troubleshooting
- If you r facing issues like `curl command not found` then use this command to install curl and then run the above installation command that starts with curl
```bash
sudo apt update && sudo apt install curl
```
- If you r facing issues like `wget command not found` then use this command to install wget and then run the above installation command that starts with wget
```bash
sudo apt update && sudo apt install wget
```
