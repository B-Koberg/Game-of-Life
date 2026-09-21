module gol_utils
    use parameters
    use omp_lib
    implicit none
    private
    
    public :: initialize_board, step_generation, swap_boards, count_neighbors
contains

    subroutine initialize_board(board_local)
        integer, intent(inout) :: board_local(nx, ny)

        integer :: x, y

        real :: r

        board_local = 0
        
        select case (preset)
            case ('verticle_lines')
                do y = 1, ny
                    do x = 1, nx
                        if (mod(x,10) == 0) then
                            board_local(x, y) = 1
                        end if
                    end do
                end do
            case ('random')
                do y = 1, ny
                    do x = 1, nx
                        call random_number(r)
                        if (r < 0.5) then
                            board_local(x, y) = 1
                        end if
                    end do
                end do
            case default
                call exit_with_error('Error: Invalid preset in JSON. Expected verticle_lines or random.')
        end select
    end subroutine initialize_board

    subroutine step_generation(board_current, board_next)
        integer, intent(in) :: board_current(nx, ny)
        integer, intent(out) :: board_next(nx, ny)

        integer :: x, y, neighbors
        integer :: omp_nthreads

        logical :: omp_checked = .false.

        board_next = 0

        omp_nthreads = 1
        !$omp parallel shared(board_current, board_next, omp_nthreads) &
        !$omp& private(x, y, neighbors)
            !$omp single
            omp_nthreads = omp_get_num_threads()
            !$omp end single
            !$omp do schedule(static)
            do y = 1, ny
                do x = 1, nx
                    neighbors = count_neighbors(board_current, x, y)

                    if (board_current(x, y) == 1) then
                        if (neighbors == 2 .or. neighbors == 3) board_next(x, y) = 1
                    else
                        if (neighbors == 3) board_next(x, y) = 1
                    end if
                end do
            end do
            !$omp end do
        !$omp end parallel

        if (.not. omp_checked) then
            omp_checked = .true.
            if (omp_nthreads > 1) then
                write(*,'(A,I0,A)') 'step_generation: ', omp_nthreads, ' Threads aktiv'
            else
                write(*,'(A)') 'step_generation: SERIELL'
            end if
        end if
    end subroutine step_generation

    subroutine swap_boards(board_current, board_next)
        integer, intent(inout) :: board_current(nx, ny)
        integer, intent(inout) :: board_next(nx, ny)

        board_current = board_next
        board_next = 0
    end subroutine swap_boards

    integer function count_neighbors(board, x, y) result(neighbors)
        integer, intent(in) :: x, y
        integer, intent(in) :: board(nx, ny)

        integer :: left_x, right_x, upper_y, lower_y

        ! Periodisch: Werte am Rand wrappen, sonst Guards gegen Rand
        if (periodicity) then
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

            if (y == 1) then
                upper_y = ny
            else
                upper_y = y - 1
            end if

            if (y == ny) then
                lower_y = 1
            else
                lower_y = y + 1
            end if
        else
            left_x = x - 1
            right_x = x + 1
            upper_y = y - 1
            lower_y = y + 1
        end if

        neighbors = 0
        if (periodicity .or. y > 1) neighbors = neighbors + board(x, upper_y)
        if (periodicity .or. y < ny) neighbors = neighbors + board(x, lower_y)

        if (periodicity .or. x > 1) then
            if (periodicity .or. y > 1) neighbors = neighbors + board(left_x, upper_y)
            neighbors = neighbors + board(left_x, y)
            if (periodicity .or. y < ny) neighbors = neighbors + board(left_x, lower_y)
        end if

        if (periodicity .or. x < nx) then
            if (periodicity .or. y > 1) neighbors = neighbors + board(right_x, upper_y)
            neighbors = neighbors + board(right_x, y)
            if (periodicity .or. y < ny) neighbors = neighbors + board(right_x, lower_y)
        end if
    end function count_neighbors

end module gol_utils
