# meshlemming
This script changes the mesh channels to secure that always the best mesh partner is available.
Beware of possible channel flapping!

Start as micron.d cronjob
cat /usr/lib/micron.d/meshlemming
*/30 * * * * /root/meshlemming.sh
