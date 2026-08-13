module gol_utils
    use mpi_f08
    use parameters, only: nx, ny
    implicit none
    private

    public :: initialize_board, step_generation, swap_boards, count_neighbors
contains

    subroutine initialize_board(board_local, local_ny, rank)
        integer, intent(in) :: local_ny, rank
        integer, intent(inout) :: board_local(nx, 0:local_ny+1)

        integer :: x, y

        board_local = 0

        do y = 1, local_ny
            do x = 1, nx
                if (mod(x,10) == 0) then
                    board_local(x, y) = 1
                end if
                !random board, später geziehlter 
            end do
        end do
    end subroutine initialize_board

    subroutine step_generation(board_current, board_next, local_ny)
        integer, intent(in) :: local_ny
        integer, intent(in) :: board_current(nx, 0:local_ny+1)
        integer, intent(out) :: board_next(nx, 0:local_ny+1)

        integer :: x, y, neighbors

        board_next = 0

        do y = 1, local_ny
            do x = 1, nx
                neighbors = count_neighbors(board_current, x, y, local_ny)

                if (board_current(x, y) == 1) then
                    if (neighbors == 2 .or. neighbors == 3) board_next(x, y) = 1
                else
                    if (neighbors == 3) board_next(x, y) = 1
                end if
            end do
        end do
    end subroutine step_generation

    subroutine swap_boards(board_current, board_next, local_ny)
        integer, intent(in) :: local_ny
        integer, intent(inout) :: board_current(nx, 0:local_ny+1)
        integer, intent(inout) :: board_next(nx, 0:local_ny+1)

        integer :: tmp(nx, 0:local_ny+1)

        tmp = board_current
        board_current = board_next
        board_next = 0
    end subroutine swap_boards

    integer function count_neighbors(board_local, x, y, local_ny) result(neighbors)
        integer, intent(in) :: local_ny, x, y
        integer, intent(in) :: board_local(nx, 0:local_ny+1)

        integer :: left_x, right_x

        if (x == 1) then
            left_x = nx
        else
            left_x = x - 1
        end if

        if (x == nx) then
            right_x = 1
        else
            right_x = x + 1
        end if

        neighbors = 0
        neighbors = neighbors + board_local(left_x, y - 1)
        neighbors = neighbors + board_local(x, y - 1)
        neighbors = neighbors + board_local(right_x, y - 1)
        neighbors = neighbors + board_local(left_x, y)
        neighbors = neighbors + board_local(right_x, y)
        neighbors = neighbors + board_local(left_x, y + 1)
        neighbors = neighbors + board_local(x, y + 1)
        neighbors = neighbors + board_local(right_x, y + 1)
    end function count_neighbors

end module gol_utils
