module mpi_utils
    use mpi_f08
    use parameters
    implicit none
    private
    public :: split_arrays, gather_2d
contains
    subroutine split_arrays(y_pix, y_pix_local, local_ny, rank, size)
        integer, intent(in) :: rank, size
        integer, intent(in) :: y_pix(ny)
        integer, intent(out), allocatable :: y_pix_local(:)
        integer, intent(out) :: local_ny

        integer :: starty, endy
        integer :: block

        block = ny / size
        starty = rank*block + 1
        endy   = (rank+1)*block
        if (rank == size-1) endy = ny

        if (starty > endy) then
            stop "Error: More processes than work items"
        else
            local_ny = endy - starty + 1
        end if

        allocate(y_pix_local(local_ny))
        y_pix_local = y_pix(starty:endy)
    end subroutine split_arrays

    subroutine gather_2d(iter_array, iter_array_local, local_ny, size)
        integer, intent(in) :: local_ny, size
        integer, intent(in) :: iter_array_local(nx, local_ny)
        integer, intent(out) :: iter_array(nx, ny)
        integer, allocatable :: recvcounts(:), displs(:)

        integer :: p, tmp_start, tmp_end, block

        block = ny / size

        allocate(recvcounts(size), displs(size))

        do p = 0, size-1
            tmp_start = p*block + 1
            tmp_end   = (p+1)*block
            if (p == size-1) tmp_end = ny

            recvcounts(p+1) = (tmp_end - tmp_start + 1) * nx
        end do

        displs(1) = 0
        do p = 2, size
            displs(p) = displs(p-1) + recvcounts(p-1)
        end do


        call MPI_Gatherv( &
            iter_array_local, nx*local_ny, MPI_INTEGER, &
            iter_array, recvcounts, displs, MPI_INTEGER, &
            0, MPI_COMM_WORLD)

        !MPI_Gatherv(
        !Was sende ich?,
        !Wie viele Elemente sende ich?,
        !Welcher Datentyp?,
        !Wohin wird gesammelt?,
        !Wie viel kommt von jedem Rank?,
        !Wo wird jedes Paket abgelegt?,
        !Welcher Datentyp wird empfangen?,
        !Wer sammelt?,
        !In welchem Communicator?
        !)
    end subroutine

end module mpi_utils