module GOL
	use mpi_f08
	use parameters, only: nx, ny
	implicit none
	private

	public :: initialize_board
	public :: exchange_halos
	public :: step_generation
	public :: swap_boards

contains
	subroutine initialize_board(board_local, local_ny, rank)
		integer, intent(in) :: local_ny, rank
		integer, intent(inout) :: board_local(nx, 0:local_ny+1)

		integer :: x, y

		board_local = 0

		do y = 1, local_ny
			do x = 1, nx
				if (mod(x * 37 + (y + rank * local_ny) * 17, 23) == 0) then
					board_local(x, y) = 1
				end if
			end do
		end do
	end subroutine initialize_board

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

	subroutine step_generation(current, next, local_ny)
		integer, intent(in) :: local_ny
		integer, intent(in) :: current(nx, 0:local_ny+1)
		integer, intent(out) :: next(nx, 0:local_ny+1)

		integer :: x, y, neighbors

		next = 0

		do y = 1, local_ny
			do x = 1, nx
				neighbors = count_neighbors(current, x, y, local_ny)

				if (current(x, y) == 1) then
					if (neighbors == 2 .or. neighbors == 3) next(x, y) = 1
				else
					if (neighbors == 3) next(x, y) = 1
				end if
			end do
		end do
	end subroutine step_generation

	subroutine swap_boards(current, next, local_ny)
		integer, intent(in) :: local_ny
		integer, intent(inout) :: current(nx, 0:local_ny+1)
		integer, intent(inout) :: next(nx, 0:local_ny+1)

		integer :: tmp(nx, 0:local_ny+1)

		tmp = current
		current = next
		next = tmp
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

end module GOL
