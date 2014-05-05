# Aliases for basic ROS applications
imview () { for i in "$@"; do (rosrun image_view image_view image:=$i &); done }
dispview () { rosrun image_view disparity_view image:=$1; }
rviz() { rosrun rviz rviz; }
dashboard() { rosrun pr2_dashboard pr2_dashboard; }

reconfigure()
{
  for i in $(eval echo {1..$1})
  do
    echo "Spawning a reconfigure gui..."
    rosrun dynamic_reconfigure reconfigure_gui &
  done
}

manager() { rosrun pr2_controller_manager pr2_controller_manager; }
sixaxis() { roslaunch pr2_teleop teleop_joystick.launch; }
alias gtopic='rostopic list | sort -u | grep'

# Computers (hosts)
alias jks-g51='export ROS_MASTER_URI=http://jks-g51:11311'
alias stair4a='export ROS_MASTER_URI=http://stair4a:11311'
alias jks-al='export ROS_MASTER_URI=http://jks-al:11311'
alias jks-prbase='export ROS_MASTER_URI=http://jks-prbase:11311'
alias ael-w530='export ROS_MASTER_URI=http://ael-w530:11311'


function ws()
{
    cd $HOME/ros/"$1"
    export ROS_WS=$PWD
    export ROS_WORKSPACE=$ROS_WS
    if [ -f setup.bash ]; then
        echo "Sourcing setup.bash"
        source setup.bash
    fi;

    # create a ros environment loader
    echo "Creating env loader"
    make_env_loader.py $ROS_WS
    export ROS_ENV_LOADER=$ROS_WS/env.sh
}


function fuerte() { source /opt/ros/fuerte/setup.bash; }
function groovy() { source /opt/ros/groovy/setup.bash; }
function hydro()  { source /opt/ros/hydro/setup.bash; }
function indigo() { source /opt/ros/indigo/setup.bash; }

function demos()
{
  source ~/ros/groovy_precise/cat_ws/devel/setup.bash
  export ROS_WORKSPACE=~/ros/groovy_precise/cat_ws
  export ROS_MASTER_URI=http://c1:11311
  export ROS_IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
}
