package server

import "core:fmt"
import "core:net"
import "core:os"

// [0] message_type
// [1] options
// [2..=3] payload (u16)
// payload could be:

Packet :: [4]u8

Message_Type :: enum(u8) {
    Move_Up,
    Move_Down,
}

Packet_Option :: enum(u8) {
    None,
    Player1,
    Player2,
}

main :: proc() {
    server_address := net.parse_address("0.0.0.0:36936")
    socket, err := net.make_bound_udp_socket(server_address, 36936)
    if err != nil {
        fmt.println("Failed to open socket:", err)
        return
    }
    defer net.close(socket)

    buffer := make([]u8, 1024)

    player_1_pos: u16
    player_2_pos: u16
    ball_x: u16
    ball_y: u16
    player_1_score: u16
    player_2_score: u16

    send_packet :: proc(msgt, opts: u8, payload: u16, socket: net.UDP_Socket, client_address: net.Endpoint) {
        p := [4]u8{msgt, opts, 0, 0}
        pos := p[2:][:2]
        pack_u16(&pos, payload)
        _, err := net.send_udp(socket, p[:], client_address)
        if err != nil {
            fmt.println("Failed to send packet:", err)
        }
    }

    for {
        bytes_read, client_address, err := net.recv_udp(socket, buffer)
        if err != nil {
            fmt.println("Failed to receive data:", err)
            continue
        }

        fmt.printf("Received message (%d bytes): %x\n", bytes_read, buffer[:bytes_read])

        if bytes_read == 2 {
            msgt := Message_Type(buffer[0])
            opts := Packet_Option(buffer[1])

            switch msgt {
            case .Move_Down:
                switch opts {
                case .None:
                case .Player1:
                    if i16(player_1_pos) - 10 < 0 {
                        player_1_pos = 0
                    } else {
                        player_1_pos -= 10
                    }
                    send_packet(0, 1, player_1_pos, socket, client_address)
                case .Player2:
                    if i16(player_2_pos) - 10 < 0 {
                        player_2_pos = 0
                    } else {
                        player_2_pos -= 10
                    }
                    send_packet(0, 2, player_2_pos, socket, client_address)
                }
            case .Move_Up:
                switch opts {
                case .None:
                case .Player1:
                    player_1_pos += 10
                    send_packet(0, 1, player_1_pos, socket, client_address)
                case .Player2:
                    player_2_pos += 10
                    send_packet(0, 2, player_2_pos, socket, client_address)
                }
            }
        }

        // if bytes_read == 4 {
        //     _, err = net.send_udp(socket, packet[:], client_address)
        //     if err != nil {
        //         fmt.println("Failed to send response:", err)
        //         continue
        //     }
        // }
    }
}

pack_u16 :: proc(buf: ^[]u8, v: u16) {
    buf[0] = u8((v >> 8) & 0xFF)
    buf[1] = u8((v >> 0) & 0xFF)
}

pack_u32 :: proc(buf: ^[]u8, v: u32) {
    buf[0] = u8((v >> 24) & 0xFF)
    buf[1] = u8((v >> 16) & 0xFF)
    buf[2] = u8((v >> 8) & 0xFF)
    buf[3] = u8((v >> 0) & 0xFF)
}