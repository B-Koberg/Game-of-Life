module parameters
    use mpi_f08
    use iso_fortran_env, only: int32, real64, real32
    use json_module
    implicit none
    private
    public :: wp
    public :: nx, ny
    public :: frames, delta_frames
    public :: periodicity, preset
    public :: output_file

    public :: load_parameters, MPI_exit_with_error

    integer :: wp = real64

    real :: ratio_x, ratio_y 
    real :: base_size 
    integer :: nx, ny

    integer :: frames, delta_frames

    logical :: periodicity
    character(len=:), allocatable :: preset

    character(len=:), allocatable :: output_file
contains
    subroutine load_parameters(file)
        character(len=*), intent(in) :: file
        logical :: is_found
        type(json_file) :: json
        character(len=:), allocatable :: wp_string

        call json%initialize()

        call json%load_file(file)
        if (json%failed()) stop 'Failed to load JSON file'

        json_block: block
            call json%get('wp', wp_string, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load wp from JSON file')
            call json%get('ratio_x', ratio_x, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load ratio_x from JSON file')
            call json%get('ratio_y', ratio_y, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load ratio_y from JSON file')
            call json%get('base_size', base_size, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load base_size from JSON file')
            call json%get('frames', frames, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load frames from JSON file')
            call json%get('delta_frames', delta_frames, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load delta_frames from JSON file')
            call json%get('periodicity', periodicity, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load periodicity from JSON file')
            call json%get('preset', preset, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load preset from JSON file')
            call json%get('output_file', output_file, is_found); if (.not. is_found) call MPI_exit_with_error('Failed to load output_file from JSON file')
        end block json_block

        select case (wp_string)
            case ('real64')
                wp = real64
            case ('real32')
                wp = real32
            case default
                call MPI_exit_with_error('Error: Invalid wp in JSON. Expected real64 or real32.')
        end select

        if (frames /= int(frames)) then
            call MPI_exit_with_error('Error: frames must be an integer value.')
        end if
        if (delta_frames /= int(delta_frames)) then
            call MPI_exit_with_error('Error: delta_frames must be an integer value.')
        end if

        preset = trim(preset)
        
        nx = ratio_x * base_size
        ny = ratio_y * base_size    


        call json%destroy()
    end subroutine load_parameters

    subroutine MPI_exit_with_error(message)
        character(len=*), intent(in) :: message
        integer :: ierr

        print *, message
        call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
    end subroutine MPI_exit_with_error

end module parameters
