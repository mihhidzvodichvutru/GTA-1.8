# 📦 GTA 1.8: Urban Delivery & Survival

*(Scroll down for the Vietnamese version / Kéo xuống để xem bản Tiếng Việt)*

---

## 🇬🇧 English Version

### 📖 Project Overview
GTA 1.8 is a top-down 2D game that merges Delivery and Survival mechanics. Players control a delivery driver navigating a complex urban traffic system, fulfilling orders while actively managing a dynamic Wanted Level and evading the game's built-in AI entities (Police forces and hostile NPCs). 

The project heavily emphasizes the implementation of Pathfinding algorithms, Finite State Machines (FSM) for AI behaviors, and Multi-Viewport HUD optimization.

### ⚡ Technical Highlights

*   **Dynamic Police AI (FSM & Soft Separation):**
    *   Architected a Finite State Machine for police units, handling seamless transitions between `PATROL` (randomized guarding) and `CHASE` (active pursuit) states.
    *   Integrated pathfinding via `NavigationAgent2D` to compute trajectories and dynamically avoid moving obstacles.
    *   Engineered a custom Soft Separation algorithm leveraging a `nearby_peers` array to calculate displacement vectors (`_get_separation_vector`), effectively preventing AI node stacking and clipping during swarm pursuits.

*   **Advanced Pathfinding & Routing:**
    *   Implemented real-time GPS routing by combining `AStarGrid2D` with `NavigationServer2D`.
    *   Designed a system that automatically queries the Navigation Polygon and renders the optimal trajectory (`Line2D`) from the player's current coordinate to randomly generated delivery waypoints.

*   **City-map Infrastructure & Multi-Viewport UI:**
    *   Constructed the urban environment utilizing a multi-layer TileMap system, fully integrated with physics colliders (`StaticBody2D`, `Area2D`) for buildings and interactive traffic lights.
    *   Developed a complex smartphone-simulated HUD using `SubViewportContainer` to concurrently render two independent camera views (a Minimap and a pseudo-Google Map) on a single screen.
    *   Applied Linear Interpolation (Lerp) for Dynamic Camera Zoom, inversely scaling the Minimap viewport relative to the vehicle's velocity to enhance high-speed visibility.
    *   Programmed custom Shaders to handle real-time background blur effects during UI interactions.

### 🛠 Tech Stack
*   **Engine:** Godot Engine 4.x (Forward+ Renderer)
*   **Language:** GDScript
*   **Architecture/Systems:** Node-based architecture, Signal-driven event handling, 2D Physics Engine (Jolt Physics integration).

### 🚀 Local Setup

This project requires **Godot Engine version 4.x** or higher.

1. Clone the repository:
   ```bash
   git clone [https://github.com/mihhidzvodichvutru/GTA-1.8.git]
   ```

2. Open Godot Engine, select **Import**, and locate the `project.godot` file in the root directory.
3. In the Godot Editor, open the main scene at `res://main_map.tscn`.
4. Press **F5** (or the Play button) to compile and run the project.

### 🕹️ Basic Controls
*   **W / Up Arrow:** Accelerate
*   **A, D / Left, Right Arrows:** Steer
*   **S / Down Arrow:** Brake / Reverse
*   **F:** Interact / Complete Delivery (at designated drop-off zones)
*   **Tab:** Toggle Smartphone HUD (Expanded Map)
*   **ESC:** Pause Menu

---

## 🇻🇳 Bản Tiếng Việt

### 📖 Tổng quan dự án
GTA 1.8 là một tựa game 2D góc nhìn từ trên xuống (top-down) kết hợp giữa cơ chế giao hàng (Delivery) và sinh tồn (Survival). Người chơi điều khiển một nhân vật shipper điều hướng qua hệ thống giao thông đô thị phức tạp, hoàn thành các đơn hàng trong khi phải quản lý mức độ truy nã (Wanted Level) và lẩn tránh hệ thống AI nội tại của bản đồ (Cảnh sát, kẻ địch NPC). 

Dự án tập trung vào việc xử lý các thuật toán tìm đường (Pathfinding), máy trạng thái hữu hạn (State Machine) cho AI, và tối ưu hóa hệ thống giao diện đa luồng (Multi-Viewport HUD).

### ⚡ Điểm nhấn Kỹ thuật

*   **Hệ thống AI Cảnh sát (Dynamic Police AI):**
    *   Thiết kế kiến trúc State Machine cho lực lượng cảnh sát với hai trạng thái chính: `PATROL` (Tuần tra ngẫu nhiên quanh chốt) và `CHASE` (Truy đuổi mục tiêu).
    *   Tích hợp thuật toán dò đường thông qua `NavigationAgent2D` để xử lý quỹ đạo di chuyển né vật cản động.
    *   Xây dựng thuật toán phân tách bầy đàn (Soft Separation) dựa trên mảng `nearby_peers` để tự động tính toán véc-tơ đẩy (`_get_separation_vector`), ngăn chặn tình trạng các node AI bị đè lên nhau (stacking) khi cùng truy đuổi một mục tiêu.

*   **Hệ thống Điều hướng & Tìm đường (Advanced Pathfinding):**
    *   Xử lý logic dẫn đường thời gian thực (GPS Routing) bằng cách kết hợp `AStarGrid2D` và `NavigationServer2D`. 
    *   Hệ thống tự động quét bản đồ (Navigation Polygon) và vẽ quỹ đạo tối ưu (`Line2D`) từ xe của người chơi đến tọa độ điểm giao hàng được sinh ngẫu nhiên.

*   **Hạ tầng Bản đồ & Tối ưu UI (City-map & Multi-Viewport):**
    *   Xây dựng môi trường bằng hệ thống TileMap nhiều lớp, kết hợp hệ thống va chạm vật lý (StaticBody2D, Area2D) cho các công trình và tín hiệu đèn giao thông.
    *   Phát triển giao diện HUD phức tạp mô phỏng điện thoại thông minh, sử dụng `SubViewportContainer` để render hai hệ thống camera độc lập (Minimap và Google Map giả lập) trên cùng một màn hình.
    *   Xử lý camera động (Dynamic Zoom): Áp dụng nội suy tuyến tính (Lerp) để thay đổi độ thu phóng của Minimap tỷ lệ thuận với vận tốc xe, cải thiện tầm nhìn khi di chuyển ở tốc độ cao.
    *   Lập trình Shader tùy chỉnh để tạo hiệu ứng làm mờ (Blur effect) khi tương tác với giao diện UI.

### 🛠 Công nghệ sử dụng
*   **Engine:** Godot Engine 4.x (Forward+ Renderer)
*   **Ngôn ngữ:** GDScript
*   **Kiến trúc:** Hệ thống Node-based, Signal-driven event handling, và 2D Physics Engine (Jolt Physics).

### 🚀 Hướng dẫn khởi chạy (Local Setup)

Dự án yêu cầu **Godot Engine phiên bản 4.x** trở lên.

1. Clone kho lưu trữ về máy:
   ```bash
   git clone [https://github.com/mihhidzvodichvutru/GTA-1.8.git]
   ```

2. Mở Godot Engine, chọn **Import** (Nhập) và trỏ tới tệp `project.godot` nằm trong thư mục gốc của dự án.
3. Trong Godot Editor, mở Scene chính tại đường dẫn `res://main_map.tscn`.
4. Nhấn **F5** (hoặc nút Play ở góc trên bên phải) để biên dịch và khởi chạy game.

### 🕹️ Điều khiển cơ bản
*   **W / Phím mũi tên lên:** Tăng tốc
*   **A, D / Mũi tên trái, phải:** Điều hướng
*   **S / Mũi tên xuống:** Phanh / Lùi
*   **F:** Tương tác / Giao hàng tại điểm đến (Vùng sáng)
*   **Tab:** Mở/Đóng điện thoại (Bản đồ lớn)
*   **ESC:** Tạm dừng (Pause Menu)
