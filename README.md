# Dobot Atom - Hiển thị RViz bằng Docker

Repo này là bản chỉnh sửa phục vụ mục đích cá nhân để hiển thị mô hình Dobot Atom bằng RViz trong Docker, sau đó xuất giao diện đồ họa ra Windows thông qua XLaunch/VcXsrv. Phần mô hình robot, mesh, URDF/xacro và cấu hình gốc được tham khảo từ repo [Dobot-Arm/dobot_atom_ros2](https://github.com/Dobot-Arm/dobot_atom_ros2). Repo này không tuyên bố là mã nguồn gốc của Dobot Atom; các thay đổi chính tập trung vào việc đóng gói môi trường ROS 2 và launch RViz sao cho có thể chạy cô lập trong container.

## Mục tiêu

Mục tiêu chính của repo là hiển thị robot Dobot Atom trong RViz trên máy Windows mà không cần cài trực tiếp ROS 2 lên host. Docker container chạy ROS 2 Humble, `robot_state_publisher`, `joint_state_publisher_gui`, `xacro` và `rviz2`; XLaunch/VcXsrv trên Windows nhận cửa sổ GUI từ container qua X11. Đây là hiển thị động học để kiểm tra mô hình, link, joint, mesh và slider khớp trong RViz, chưa phải mô phỏng vật lý kiểu Gazebo/Isaac vì repo này chưa có world, plugin mô phỏng, controller runtime hoặc node điều khiển phần cứng.

## Nguồn tham khảo

- Repo gốc: [Dobot-Arm/dobot_atom_ros2](https://github.com/Dobot-Arm/dobot_atom_ros2)
- Package sử dụng trong repo này: `dobot_atom_description`
- Nội dung kế thừa/tham khảo: `meshes`, `urdf`, `xacro`, `config`
- Nội dung bổ sung cho mục tiêu Docker/RViz: `Dockerfile`, `.dockerignore`, `launch/display.launch.py`, `config/rviz/display.rviz` và các phụ thuộc runtime trong `package.xml`

Khi dùng lại model hoặc mesh cho mục đích khác, cần kiểm tra license và điều kiện sử dụng từ repo gốc hoặc từ Dobot.

## Luồng chạy

Luồng chạy chính là: Windows host chạy XLaunch/VcXsrv, Docker container chạy ROS 2 và RViz, RViz hiển thị qua biến môi trường `DISPLAY=host.docker.internal:0.0`. Trong container, `display.launch.py` sinh `robot_description` từ `xacro/robot.xacro`, đưa mô tả robot cho `robot_state_publisher`, mở `joint_state_publisher_gui` để điều chỉnh các khớp và mở `rviz2` với cấu hình trong `config/rviz/display.rviz`.

## Chuẩn bị XLaunch trên Windows

Mở XLaunch/VcXsrv với các lựa chọn sau:

1. `Multiple windows`
2. `Start no client`
3. Bật `Disable access control`
4. Hoàn tất cấu hình và để XLaunch tiếp tục chạy nền

Nếu RViz không hiện cửa sổ, nguyên nhân thường nằm ở X server chưa chạy, Windows Firewall chặn VcXsrv hoặc chưa bật `Disable access control`.

## Tạo Docker image

Chạy trong thư mục gốc của repo:

```powershell
docker build -t dobot_atom_description:humble .
```

Image này build ROS 2 workspace tại `/ros2_ws`, cài các gói cần thiết cho RViz và chạy `colcon build --packages-up-to dobot_atom_description --symlink-install`.

## Chạy RViz toàn thân

```powershell
docker run --rm -it --name dobot_atom_description_rviz `
  -e DISPLAY=host.docker.internal:0.0 `
  -e QT_X11_NO_MITSHM=1 `
  -e LIBGL_ALWAYS_SOFTWARE=1 `
  dobot_atom_description:humble `
  bash -lc "source /ros2_ws/install/setup.bash && ros2 launch dobot_atom_description display.launch.py type:=full"
```

## Chạy RViz nửa thân trên

```powershell
docker run --rm -it --name dobot_atom_description_rviz_upper `
  -e DISPLAY=host.docker.internal:0.0 `
  -e QT_X11_NO_MITSHM=1 `
  -e LIBGL_ALWAYS_SOFTWARE=1 `
  dobot_atom_description:humble `
  bash -lc "source /ros2_ws/install/setup.bash && ros2 launch dobot_atom_description display.launch.py type:=upper"
```

Hai lệnh trên chỉ tạo container tạm thời mới với tên riêng và tự xóa khi tiến trình thoát nhờ `--rm`. Chúng không dừng, xóa hoặc sửa các container đang tồn tại. Nếu tên container đang được dùng, Docker sẽ báo lỗi trùng tên; khi đó cần đổi giá trị `--name` hoặc thoát container cũ do chính lệnh này tạo ra.

## Kiểm tra bên trong container

Có thể mở shell tạm thời để kiểm tra package:

```powershell
docker run --rm -it --name dobot_atom_description_shell dobot_atom_description:humble
```

Trong container:

```bash
source /ros2_ws/install/setup.bash
ros2 pkg prefix dobot_atom_description
xacro /ros2_ws/install/dobot_atom_description/share/dobot_atom_description/xacro/robot.xacro type:=full > /tmp/dobot_atom.urdf
```

## Giới hạn hiện tại

Repo này hiện phục vụ hiển thị bằng RViz. Các lệnh demo phụ thuộc `robot_common_launch`, `ocs2_arm_controller`, Gazebo, Isaac hoặc controller runtime không được đóng gói trong image này. Nếu cần mô phỏng vật lý, cần bổ sung stack mô phỏng tương ứng, controller, world, plugin và launch file riêng thay vì chỉ dùng description package.
