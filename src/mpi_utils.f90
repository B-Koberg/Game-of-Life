module mpi_utils
    use hdf5
    use mpi_f08
    use parameters
    use hdf5_utils, only: hdf5_write_frame
    implicit none
    private
    public :: split_arrays, exchange_halos, gather_and_save

    integer, allocatable :: frames_buffer(:,:,:)
    logical :: buffer_ready = .false.
contains
    subroutine split_arrays(local_ny, rank, size)
        integer, intent(in) :: rank, size
        integer, intent(out) :: local_ny

        integer :: start_y, end_y
        integer :: block

        block = ny / size
        start_y = rank*block + 1
        end_y   = (rank+1)*block
        if (rank == size-1) end_y = ny

        if (start_y > end_y) then
            stop "Error: More processes than work items"
        else
            local_ny = end_y - start_y + 1
        end if
    end subroutine split_arrays

    subroutine exchange_halos(board_local, local_ny, rank, size)
        integer, intent(in) :: local_ny, rank, size
        integer, intent(inout) :: board_local(nx, 0:local_ny+1)

        integer :: ierr
        type(MPI_Status) :: status
        integer :: upper_rank, lower_rank

        upper_rank = rank - 1
        lower_rank = rank + 1

        if (upper_rank < 0) upper_rank = size - 1
        if (lower_rank >= size) lower_rank = 0

        ! Send last real row downward, receive upper halo from upper neighbor
        call MPI_Sendrecv( &
            board_local(:, local_ny), nx, MPI_INTEGER, lower_rank, 1, &
            board_local(:, 0), nx, MPI_INTEGER, upper_rank, 1, &
            MPI_COMM_WORLD, status, ierr)

        ! Send first real row upward, receive lower halo from lower neighbor
        call MPI_Sendrecv( &
            board_local(:, 1), nx, MPI_INTEGER, upper_rank, 2, &
            board_local(:, local_ny + 1), nx, MPI_INTEGER, lower_rank, 2, &
            MPI_COMM_WORLD, status, ierr)
    end subroutine exchange_halos

    subroutine gather_and_save(board_current, local_ny, rank, size, frame, dset_id, filespace_id, memspace_id)
        integer, intent(in) :: local_ny, rank, size, frame
        integer, intent(in) :: board_current(nx, 0:local_ny+1)
        integer(HID_T), intent(in) :: dset_id, filespace_id, memspace_id

        integer :: sendcount, p
        integer, allocatable :: recvcounts(:), displs(:)
        integer, allocatable :: global(:,:)

        sendcount = nx * local_ny

        allocate(recvcounts(size), displs(size))

        ! Sammle die local_ny Werte auf Rank 0
        call MPI_Gather(local_ny, 1, MPI_INTEGER, recvcounts, 1, MPI_INTEGER, 0, MPI_COMM_WORLD)

        if (rank == 0) then
            displs(1) = 0
            do p = 2, size
                displs(p) = displs(p-1) + recvcounts(p-1) * nx
            end do

            allocate(global(nx, ny))

            ! rank 0 sammelt alle local boards in global array. 
            ! Sendcounts, revcounts und displs sind wichtig für die Menge, form und Position der Daten die gesammelt werden sollen
            ! (:,1) ist Startposition (0-zeile ist Halo), sencount nimmt nur bis local_ny zeile
            call MPI_Gatherv(board_current(:,1), sendcount, MPI_INTEGER, &
                            global, recvcounts*nx, displs, MPI_INTEGER, 0, MPI_COMM_WORLD)

            ! Schreibe global in HDF5 Datei
            call hdf5_write_frame(dset_id, filespace_id, memspace_id, frame-1, global)

            deallocate(global)
        else
            ! Gatherv ist kollektiv. Alle ranks müssen die Funktion aufrufen
            call MPI_Gatherv(board_current(:,1), sendcount, MPI_INTEGER, &
                            recvcounts, recvcounts, displs, MPI_INTEGER, 0, MPI_COMM_WORLD)
        end if

        deallocate(recvcounts, displs)
    end subroutine gather_and_save

end module mpi_utils