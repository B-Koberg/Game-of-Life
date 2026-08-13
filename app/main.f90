program GOL
    use mpi_f08
    use hdf5
    use parameters
    use mpi_utils, only: split_arrays, exchange_halos, gather_and_save
    use gol_utils, only: initialize_board, step_generation, swap_boards
    use hdf5_utils, only: hdf5_init_run, hdf5_write_frame, hdf5_close_run
    implicit none

    integer :: rank, size
    integer :: frame

    integer :: local_ny

    !Brauche File-ID, Dataset-ID, Filespace-ID (beschreibt größe / format), Memspace-ID (Ram zuordnung)
    integer(HID_T) :: file_id, dset_id, filespace_id, memspace_id

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


    if (rank == 0) call hdf5_init_run("output/frames.hdf5", file_id, dset_id, filespace_id, memspace_id)


    call gather_and_save(board_current, local_ny, rank, size, 1, dset_id, filespace_id, memspace_id)

    call print_time(rank, "Begin calculation...")

    do frame = 2, frames + 1
        call exchange_halos(board_current, local_ny, rank, size)
        call step_generation(board_current, board_next, local_ny)
        call swap_boards(board_current, board_next, local_ny)

        call gather_and_save(board_current, local_ny, rank, size, frame, dset_id, filespace_id, memspace_id)
    end do

    if (rank == 0) call hdf5_close_run(file_id, dset_id, filespace_id, memspace_id)

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