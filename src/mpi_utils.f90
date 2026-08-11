module mpi_utils
    use mpi_f08
    use parameters
    implicit none
    private
    public :: split_arrays, exchange_halos
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

        if (upper_rank < 0) upper_rank = MPI_PROC_NULL
        if (lower_rank >= size) lower_rank = MPI_PROC_NULL

        call MPI_Sendrecv( &
            board_local(:, 1), nx, MPI_INTEGER, upper_rank, 1, &
            board_local(:, 0), nx, MPI_INTEGER, upper_rank, 2, &
            MPI_COMM_WORLD, status, ierr)

        call MPI_Sendrecv( &
            board_local(:, local_ny), nx, MPI_INTEGER, lower_rank, 2, &
            board_local(:, local_ny + 1), nx, MPI_INTEGER, lower_rank, 1, &
            MPI_COMM_WORLD, status, ierr)
    end subroutine exchange_halos
end module mpi_utils