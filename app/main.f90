program GOL
    use mpi_f08
    use parameters
    use mpi_utils, only: split_arrays, exchange_halos
    use gol_utils, only: initialize_board, step_generation, swap_boards
    implicit none

    integer :: rank, size
    integer :: frame

    integer :: local_ny

    integer, allocatable :: board_current(:,:), board_next(:,:)


    call MPI_Init()
    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    call load_parameters('params.json')


    call split_arrays(local_ny, rank, size)

    allocate(board_current(nx, 0:local_ny+1))
    allocate(board_next(nx, 0:local_ny+1))

    call initialize_board(board_current, local_ny, rank)
    board_next = 0

    call print_time(rank, "Begin calculation...")

    do frame = 1, frames
        call exchange_halos(board_current, local_ny, rank, size)
        call step_generation(board_current, board_next, local_ny)
        call swap_boards(board_current, board_next, local_ny)
    end do

    if (rank == 0) call print_time(rank, "Finished Game-of-Life frame calculation")

    call MPI_Finalize()

contains
    subroutine print_time(proc_rank, message)
        integer, intent(in) :: proc_rank
        character(len=*), intent(in) :: message
        integer :: time(8)

        call date_and_time(values=time)
        write(*,'("[",I1.1,"](",I2.2,":",I2.2,":",I2.2,") ",A)') &
            proc_rank, time(5), time(6), time(7), message
    end subroutine print_time
end program GOL