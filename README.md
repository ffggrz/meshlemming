# meshlemming
This script changes the mesh channels to ensure that always the best mesh partner is available.  
Be aware of a possible jitter of the channel!


## Installation
1. create the script in `/usr/sbin/` and insert the content
    ```sh
    vi /usr/sbin/meshlemming.sh
    ```
2. make it executable
    ```sh
    chmod +x /usr/sbin/meshlemming.sh
    ```
3. run as cronjob
    ```sh
    echo "*/30 * * * * /usr/sbin/meshlemming.sh" >/usr/lib/micron.d/meshlemming
    ```
