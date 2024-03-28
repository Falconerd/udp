package client

import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
import rl "vendor:raylib"

Packet_Outgoing :: [2]u8
Packet_Incoming :: [4]u8

Message_Type_Incoming :: enum(u8) {
    Player_Position,
}

Message_Options_Incoming :: enum(u8) {
    None,
    Player1,
    Player2,
}

Message_Type_Outgoing :: enum(u8) {
    Move,
}

player_1_pos: u16

receive_data :: proc(t: ^thread.Thread) {
    buffer := make([]u8, 1024)
    socket_ptr := cast(^net.UDP_Socket)t.data

    for {
        bytes_read, _, err := net.recv_udp(socket_ptr^, buffer)
        if err != nil {
            fmt.println("Failed to receive data:", err)
            continue
        }

        fmt.printf("bytes_read: %d, u16: %d\n", bytes_read, u16_from_bytes(buffer[2:][:2]))

        msgt := Message_Type_Incoming(buffer[0])
        opts := Message_Options_Incoming(buffer[1])
        payload := buffer[2:][:bytes_read - 2]

        if msgt == .Player_Position {
            if opts == .Player1 {
                player_1_pos = u16_from_bytes(payload)
            }
        }

        // player_1_pos = i32_from_bytes(buffer[:4])
    }
}

u16_from_bytes :: proc(b: []u8) -> u16 {
    return u16(b[0]) << 8 | u16(b[1]) << 0
}

main :: proc () {
    endpoint, ok := net.parse_endpoint("127.0.0.1:36936")
    if !ok {
        fmt.println("Failed to parse endpoint.")
        return
    }

    server_address := net.parse_address("0.0.0.0:36937")
    socket, err := net.make_bound_udp_socket(server_address, 36937)
    if err != nil {
        fmt.println("Failed to open socket:", err)
        return
    }
    defer net.close(socket)

    udp_thread := thread.create(receive_data)
    udp_thread.data = &socket
    thread.start(udp_thread)

    render_width := 640
    render_height := 360
    rl.InitWindow(auto_cast(640), auto_cast(360), "UDP TEST")
    rl.rlViewport(0, 0, auto_cast(render_width), auto_cast(render_height))
    rl.SetTargetFPS(60)
    rl.SetWindowMinSize(auto_cast(render_width), auto_cast(render_height))

    for !rl.WindowShouldClose() {
        if rl.IsKeyDown(rl.KeyboardKey.F) {
            _, err := net.send_udp(socket, []byte{0, 1}, endpoint)
            if err != nil {
                // ...
            }
        }

        if rl.IsKeyDown(rl.KeyboardKey.S) {
            _, err := net.send_udp(socket, []byte{1, 1}, endpoint)
            if err != nil {
                // ...
            }
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawRectangle(20, i32(player_1_pos), 20, 80, rl.BLUE)
        rl.EndDrawing()
    }
}
