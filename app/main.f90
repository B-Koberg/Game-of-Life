program GOL
    use mpi_f08
    use parameters
    use mpi_utils, only: split_arrays, gather_2d
    implicit none

    integer :: rank, size

   

    integer, allocatable :: x_pix(:), y_pix(:), iter_array(:,:)
    integer, allocatable :: y_pix_local(:), iter_array_local(:,:)

    integer :: i, j

    integer :: local_ny

    call load_parameters('params.json')

    allocate(x_pix(nx))
    allocate(y_pix(ny))
    allocate(iter_array(nx, ny))

    x_pix = [(i, i = 1, nx)]
    y_pix = [(j, j = 1, ny)]

    call MPI_Init()
    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    if (rank == 0) call print_time(rank, "Starting Game-of-Life set calculation; Splitting arrays...")

    call split_arrays(y_pix, y_pix_local, local_ny, rank, size)
    allocate(iter_array_local(nx, local_ny))

    if (rank == 0) call print_time(rank, "Begin calculation...")


        
    call MPI_Finalize()

contains
    subroutine save_to_binary(iter_array, local_ny, rank)
        integer, intent(in) :: local_ny, rank
        integer, intent(in) :: iter_array(nx, local_ny)
        integer :: unit
        character(len=128) :: filename
        write(filename,'(A,I3.3,A)') 'output/mandelbrot_output_', rank, '.bin'

        open(newunit=unit, file=filename, access="stream", form="unformatted", status="replace")

        !vielleicht hdf5 lite variablen mit namen, typsicher
        !write(unit) real(nx,wp), real(ny,wp), real(local_ny,wp),real(max_iter,wp)

        ! Array als INTEGER(4)
        write(unit) iter_array

        close(unit)
    end subroutine save_to_binary

    subroutine print_time(rank, message)
        integer, intent(in) :: rank
        character(len=*), intent(in) :: message
        integer :: time(8)

        call date_and_time(values=time)
        write(*,'("[",I1.1,"](",I2.2,":",I2.2,":",I2.2,") ",A)') &
            rank, time(5), time(6), time(7), message
    end subroutine print_time


end program GOL